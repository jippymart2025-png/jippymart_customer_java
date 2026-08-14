import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jippymart_customer/models/customer_cart_model.dart';
import 'package:jippymart_customer/models/customer_checkout_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class CartApiService {
  CartApiService._();

  static String get _base => AppConst.outletBaseUrl;

  /// POST /co/cart/update
  static Future<bool> updateCart({
    required int customerId,
    required int productId,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final uri = Uri.parse('${_base}co/cart/update');
      final body = {
        'customerId': customerId,
        'productId': productId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

      print('[CartApi] POST $uri');
      print('[CartApi] body: $body');

      final response = await http
          .post(uri, headers: await getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      print('[CartApi] status: ${response.statusCode}');
      print('[CartApi] response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final bodyText = response.body.trim();
      if (bodyText.isEmpty) return true;

      try {
        final decoded = jsonDecode(bodyText);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success')) {
            return decoded['success'] == true;
          }
        }
      } catch (_) {
        return bodyText.toLowerCase().contains('item added to cart') ||
            bodyText.toLowerCase().contains('cart');
      }

      return true;
    } catch (e) {
      print('[CartApi] updateCart error: $e');
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
    double couponDiscount = 0,
    double deliveryTip = 0,
  }) async {
    try {
      final uri = Uri.parse('${_base}co/checkout');

      final body = {
        'customerId': customerId,
        'customerAddressId': customerAddressId,
        'outletId': outletId,
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
}
