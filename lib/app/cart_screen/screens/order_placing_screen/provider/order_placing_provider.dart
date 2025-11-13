import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:get/get.dart';

class OrderPlacingProvider extends ChangeNotifier {
  bool isLoading = true;
  bool isPlacing = false;
  int counter = 0;
  Timer? timer;

  void initFunction() {
    getArgument();
    startTimer();
  }

  void onClose() {
    timer?.cancel();
  }

  OrderModel orderModel = OrderModel();

  getArgument() async {
    try {
      // Clear cart immediately to free up memory
      await DatabaseHelper.instance.deleteAllCartProducts();

      dynamic argumentData = Get.arguments;
      if (argumentData != null) {
        orderModel = argumentData['orderModel'];
        print('DEBUG: Order received: ${orderModel.id}');
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error getting arguments: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void startTimer() {
    print('DEBUG: Starting order placement timer');
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (counter == 2) {
        // Reduced from 3 to 2 seconds
        timer.cancel();
        isPlacing = true;
        print('DEBUG: Order placement completed');
      }
      counter++;
    });
  }
}
