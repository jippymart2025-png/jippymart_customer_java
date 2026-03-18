import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

import 'package:jippymart_customer/constant/constant.dart';

import '../utils/utils/app_constant.dart';

/// Thin Paytm API + SDK wrapper.
///
/// Responsibilities:
/// - Call backend to initiate Paytm order and get txnToken + orderId
/// - Open Paytm All-in-One SDK
/// - Ask backend for final order status (server side verification)
class PaytmService {
  PaytmService._();

  /// Fallback MID (if backend doesn't return one).
  /// Prefer using the MID returned by `/paytm/initiate`.
  static const String fallbackMid = "rVjBPY03604052666374";

  /// Base URL for backend Paytm APIs.
  ///
  /// Your backend example used: http://192.168.88.26:8000/api
  /// In production we route everything via Constant.globalUrl.
  /// Make sure your backend exposes the same paths here:
  ///   - {globalUrl}api/paytm/initiate
  ///   - {globalUrl}api/paytm/callback
  ///   - {globalUrl}api/order/{orderId}
  static String get _baseUrl => "${AppConst.baseUrl}";

  /// 1) Call backend to get txnToken + orderId.
  static Future<Map<String, dynamic>?> initiatePayment({
    required String userId,
    required String amount,
  }) async {
    try {
      final uri = Uri.parse("${_baseUrl}paytm/initiate");
      final response = await http
          .post(
            uri,
            headers: const {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(<String, dynamic>{
              "user_id": userId,
              "amount": amount,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      return null;
    } catch (e) {
      // Do not crash the app – higher layers will show toast.
      // ignore: avoid_print
      print("Paytm initiatePayment error: $e");
      return null;
    }
  }

  /// 2) Start Paytm transaction via native SDK.
  ///
  static Future<Map<dynamic, dynamic>?> startTransaction({
    required String mid,
    required String orderId,
    required String txnToken,
    required String amount,
    required String callbackUrl,
    required bool isStaging,
  }) async {
    try {
      final result = await AllInOneSdk.startTransaction(
        mid,
        orderId,
        amount,
        txnToken,
        callbackUrl,
        isStaging,
        false,
        false, // disable Paytm Assist (fix Android 14+ receiver crash)
      );

      if (result is Map) {
        return result.cast<dynamic, dynamic>();
      }
      return null;
    } on PlatformException catch (e) {
      // Return structured error so UI can show real reason.
      // ignore: avoid_print
      print("Paytm startTransaction PlatformException: ${e.code} ${e.message}");
      return <dynamic, dynamic>{
        'error': true,
        'code': e.code,
        'message': e.message,
        'details': e.details?.toString(),
      };
    } catch (e) {
      // ignore: avoid_print
      print("Paytm startTransaction error: $e");
      return <dynamic, dynamic>{
        'error': true,
        'message': e.toString(),
      };
    }
  }

  /// 3) Ask backend for final order status (server‑side verification).
  static Future<Map<String, dynamic>?> checkOrderStatus(String orderId) async {
    try {
      // Must call Paytm status API (server-side), not local DB order row.
      // Backend route: GET /paytm/status/{orderId}
      final uri = Uri.parse("${_baseUrl}paytm/status/$orderId");
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      // ignore: avoid_print
      print("Paytm checkOrderStatus error: $e");
      return null;
    }
  }
}
