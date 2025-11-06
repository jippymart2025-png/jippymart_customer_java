import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:get/get.dart';

class OrderPlacingProvider extends ChangeNotifier {
  RxBool isLoading = true.obs;
  RxBool isPlacing = false.obs;
  RxInt counter = 0.obs;
  Timer? timer;

  void initFunction() {
    getArgument();
    startTimer();
  }

  void onClose() {
    timer?.cancel();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  getArgument() async {
    print('DEBUG: Getting order arguments');
    try {
      // Clear cart immediately to free up memory
      await DatabaseHelper.instance.deleteAllCartProducts();

      dynamic argumentData = Get.arguments;
      if (argumentData != null) {
        orderModel.value = argumentData['orderModel'];
        print('DEBUG: Order received: ${orderModel.value.id}');
      }

      isLoading.value = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error getting arguments: $e');
      isLoading.value = false;
      notifyListeners();
    }
  }

  void startTimer() {
    print('DEBUG: Starting order placement timer');
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (counter.value == 2) { // Reduced from 3 to 2 seconds
        timer.cancel();
        isPlacing.value = true;
        print('DEBUG: Order placement completed');
      }
      counter++;
    });
  }
}
