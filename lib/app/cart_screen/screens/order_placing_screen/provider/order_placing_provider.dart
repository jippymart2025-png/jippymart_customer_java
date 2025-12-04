import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/services/database_helper.dart';

class OrderPlacingProvider extends ChangeNotifier {
  bool isLoading = true;
  bool isPlacing = false;
  int counter = 0;
  Timer? timer;

  void initFunction({required OrderModel orderModels}) {
    // Reset state when initializing
    _resetState();
    getArgument(orderModels: orderModels);
    startTimer();
  }

  void _resetState() {
    // Cancel any existing timer
    timer?.cancel();
    // Reset state variables
    isLoading = true;
    isPlacing = false;
    counter = 0;
    timer = null;
  }

  void onClose() {
    timer?.cancel();
    _resetState();
  }

  OrderModel orderModel = OrderModel();

  getArgument({required OrderModel orderModels}) async {
    try {
      await DatabaseHelper.instance.deleteAllCartProducts();
      orderModel = orderModels;
      print('DEBUG: Order received: ${orderModel.id}');
      isLoading = false;
      // 🔑 CRITICAL FIX: Since order is already placed when we navigate here,
      // set isPlacing to true immediately to show Order ID screen
      if (orderModel.id != null && orderModel.id.toString().isNotEmpty) {
        isPlacing = true;
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error getting arguments: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void startTimer() {
    print('DEBUG: Starting order placement timer');
    // Reset counter before starting timer
    counter = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      counter++;
      if (counter >= 2) {
        // After 2 seconds, ensure order placed screen is shown
        timer.cancel();
        isPlacing = true;
        print('DEBUG: Order placement completed');
        // 🔑 CRITICAL FIX: Call notifyListeners() to update UI
        notifyListeners();
      }
    });
    notifyListeners();
  }
}
