import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/models/customer_cart_model.dart';
import 'package:jippymart_customer/models/customer_checkout_model.dart';
import 'package:jippymart_customer/models/payment_model/active_payment_mode_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class CartApiService {
  CartApiService._();

  static String get _base => AppConst.outletBaseUrl;

  /// POST /co/cart/update
  static Future<bool> updateCart({
    required int customerId,
    required int productId,
    required int outletId,
    required List<Map<String, dynamic>> variants,
  }) async {
    try {
      final uri = Uri.parse('${_base}co/cart/update');

      final body = {
        'customerId': customerId,
        'outletId': outletId,
        'productId': productId,
        'variants': variants,
      };

      debugPrint('[CartApi] POST $uri');
      debugPrint('[CartApi] body: ${jsonEncode(body)}');

      final response = await http
          .post(uri, headers: await getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      debugPrint('[CartApi] status: ${response.statusCode}');

      debugPrint('[CartApi] response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final responseBody = response.body.trim();

      if (responseBody.isEmpty) {
        return true;
      }

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success')) {
            return decoded['success'] == true;
          }
        }
      } catch (_) {
        // Response is not JSON.
      }

      return true;
    } catch (e) {
      debugPrint('[CartApi] updateCart error: $e');

      return false;
    }
  }

  /// GET /co/cart/{customerId}
  static Future<CustomerCartModel?> getCart(int customerId) async {
    try {
      final uri = Uri.parse('${_base}co/cart/$customerId');

      print('[CartApi] GET $uri');

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      print('[CartApi] status: ${response.statusCode}');
      print('[CartApi] response: ${response.body}');

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      if (decoded.containsKey('data') && decoded['data'] is Map) {
        return CustomerCartModel.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      }

      return CustomerCartModel.fromJson(decoded);
    } catch (e) {
      print('[CartApi] getCart error: $e');
      return null;
    }
  }

  /// POST /co/checkout
  static Future<CustomerCheckoutModel?> checkout({
    required int customerId,
    required int customerAddressId,
    required int outletId,
    int? couponId,
    double walletAmount = 0,
    String couponDiscount = "0",
    double deliveryTip = 0,
  }) async {
    try {
      final uri = Uri.parse('${_base}co/checkout');

      final body = {
        'customerId': customerId,
        'customerAddressId': customerAddressId,
        'outletId': outletId,
        'couponId': couponId,
        'walletAmount': walletAmount,
        'couponDiscount': couponDiscount,
        'deliveryTip': deliveryTip,
      };

      print('[CartApi] POST $uri');
      print('[CartApi] body: $body');

      final response = await http
          .post(uri, headers: await getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      print('[CartApi] status: ${response.statusCode}');
      print('[CartApi] response: ${response.body}');

      // Decode response first
      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Backend returned invalid response: ${response.body}');
      }

      // Backend error
      if (response.statusCode != 200 && response.statusCode != 201) {
        dynamic decoded;

        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          throw Exception('Checkout failed: ${response.body}');
        }

        if (decoded is Map<String, dynamic>) {
          final errorMessage =
              decoded['errorMessage']?.toString() ??
              decoded['message']?.toString() ??
              decoded['error']?.toString();

          throw Exception(errorMessage ?? 'Checkout failed');
        }

        throw Exception('Checkout failed');
      }
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid checkout response');
      }

      final data = decoded.containsKey('data') && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded;

      return CustomerCheckoutModel.fromJson(data);
    } catch (e) {
      print('[CartApi] checkout error: $e');
      rethrow;
    }
  }

  /// GET /co/order-settings/getActivePaymentModes
  static Future<List<ActivePaymentModeModel>> getActivePaymentModes() async {
    try {
      final uri = Uri.parse('${_base}co/order-settings/getActivePaymentModes');

      print('[CartApi] GET $uri');

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      print('[CartApi] status: ${response.statusCode}');
      print('[CartApi] response: ${response.body}');

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);

      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          list = data;
        } else {
          return [];
        }
      } else {
        return [];
      }

      return ActivePaymentModeModel.listFromJson(list);
    } catch (e) {
      print('[CartApi] getActivePaymentModes error: $e');
      return [];
    }
  }

  /// POST /div/payment/initiate
  ///
  /// Initiates a payment record on the backend for the current order.
  /// Returns the decoded JSON on success, otherwise `null`.
  static Future<Map<String, dynamic>?> initiatePayment({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final uri = Uri.parse('${_base}div/payment/initiate');

      print('[CartApi] POST $uri');
      print('[CartApi] body: ${jsonEncode(payload)}');

      final response = await http
          .post(uri, headers: await getHeaders(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      print('[CartApi] status: ${response.statusCode}');
      print('[CartApi] response: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          return <String, dynamic>{'success': true};
        }
        throw Exception('Invalid initiate payment response: ${response.body}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (decoded is Map<String, dynamic>) {
          final errorMessage =
              decoded['errorMessage']?.toString() ??
              decoded['message']?.toString() ??
              decoded['error']?.toString();
          throw Exception(errorMessage ?? 'Payment initiation failed');
        }
        throw Exception('Payment initiation failed');
      }

      if (decoded is! Map<String, dynamic>) {
        return <String, dynamic>{'success': true};
      }

      final data = decoded.containsKey('data') && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded;

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('[CartApi] initiatePayment error: $e');
      rethrow;
    }
  }
}
