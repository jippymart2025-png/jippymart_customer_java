import 'dart:convert';

import 'package:jippymart_customer/models/payment_model/razorpay_model.dart';
import 'package:jippymart_customer/payment/createRazorPayOrderModel.dart';
import 'package:http/http.dart' as http;

import '../constant/constant.dart';

class RazorPayController {
  Future<CreateRazorPayOrderModel?> createOrderRazorPay({
    required double amount,
    required RazorPayModel? razorpayModel,
  }) async {
    final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    RazorPayModel razorPayData = razorpayModel!;
    print(razorPayData.razorpayKey);
    print("we Enter In");

    const url = "${Constant.globalUrl}payments/razorpay/createorder";
    var bodyJson = {
      "amount": (amount.round() * 100).toString(),
      "receipt_id": orderId,
      "currency": "INR",
      "razorpaykey": razorPayData.razorpayKey,
      "razorPaySecret": razorPayData.razorpaySecret,
      "isSandBoxEnabled": razorPayData.isSandboxEnabled.toString(),
    };
    print(orderId);
    print("createOrderRazorPay $bodyJson ");
    final response = await http.post(Uri.parse(url), body: bodyJson);
    if (response.statusCode == 500) {
      return null;
    } else {
      final data = jsonDecode(response.body);
      print(data);

      return CreateRazorPayOrderModel.fromJson(data);
    }
  }
}
