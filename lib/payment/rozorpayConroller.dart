import 'dart:convert';

import 'package:jippymart_customer/models/payment_model/razorpay_model.dart';
import 'package:jippymart_customer/payment/createRazorPayOrderModel.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/common.dart';

import '../constant/constant.dart';

class RazorPayController {
  Future<CreateRazorPayOrderModel?> createOrderRazorPay({
    required double amount,
    required RazorPayModel? razorpayModel,
  }) async {
    try {
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
      RazorPayModel razorPayData = razorpayModel!;
      print("🔑 Creating RazorPay order for amount: $amount");
      const url = "${Constant.globalUrl}payments/razorpay/createorder";
      var bodyJson = {
        "amount": (amount.round() * 100).toString(),
        "receipt_id": orderId.toString(),
        "currency": "INR",
        "razorpaykey": razorPayData.razorpayKey,
        "razorPaySecret": razorPayData.razorpaySecret,
        "isSandBoxEnabled": razorPayData.isSandboxEnabled.toString(),
      };
      print("📦 Request URL: $url");
      print("📦 Request Body: $bodyJson");
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(bodyJson))
          .timeout(Duration(seconds: 30)); // Add timeout

      print("📦 Response Status: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          print("✅ RazorPay order created successfully");
          return CreateRazorPayOrderModel.fromJson(data);
        } catch (jsonError) {
          print("❌ JSON Parse Error: $jsonError");
          return null;
        }
      } else {
        print(
          "❌ RazorPay API Error: ${response.statusCode} - ${response.body}",
        );
        return null;
      }
    } catch (e, stackTrace) {
      print("❌ RazorPay Exception: $e");
      print("❌ Stack Trace: $stackTrace");
      return null;
    }
  }

  // Future<CreateRazorPayOrderModel?> createOrderRazorPay({
  //   required double amount,
  //   required RazorPayModel? razorpayModel,
  // }) async {
  //   try {
  //     final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
  //     RazorPayModel razorPayData = razorpayModel!;
  //     print(razorPayData.razorpayKey);
  //     print("we Enter In");
  //     const url = "${Constant.globalUrl}payments/razorpay/createorder";
  //     var bodyJson = {
  //       "amount": (amount.round() * 100).toString(),
  //       "receipt_id": orderId.toString(),
  //       "currency": "INR",
  //       "razorpaykey": razorPayData.razorpayKey,
  //       "razorPaySecret": razorPayData.razorpaySecret,
  //       "isSandBoxEnabled": razorPayData.isSandboxEnabled.toString(),
  //     };
  //     print(orderId);
  //     print("createOrderRazorPay ${url} $bodyJson ");
  //
  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: headers,
  //       body: jsonEncode(bodyJson),
  //     );
  //     print("createOrderRazorPay Response Status: ${response.statusCode}");
  //     print("createOrderRazorPay Response Body: ${response.body}");
  //     // First check if response is successful
  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       try {
  //         final data = jsonDecode(response.body);
  //         print("Parsed JSON data: $data");
  //         return CreateRazorPayOrderModel.fromJson(data);
  //       } catch (jsonError) {
  //         print("JSON Decode Error: $jsonError");
  //         print("Raw Response: ${response.body}");
  //         return null;
  //       }
  //     } else {
  //       print("Request failed with status: ${response.statusCode}");
  //       print("Response: ${response.body}");
  //       return null;
  //     }
  //   } catch (e, stackTrace) {
  //     print("createOrderRazorPay Exception: $e");
  //     print("Stack Trace: $stackTrace");
  //     return null;
  //   }
  // }
}
