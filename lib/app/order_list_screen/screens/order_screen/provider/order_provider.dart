import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> allList = <OrderModel>[];
  List<OrderModel> newOrderList = <OrderModel>[];
  List<OrderModel> inProgressList = <OrderModel>[];
  List<OrderModel> deliveredList = <OrderModel>[];
  List<OrderModel> rejectedList = <OrderModel>[];
  List<OrderModel> cancelledList = <OrderModel>[];
  bool isLoading = true;

  void initFunction() {
    getOrder();
  }

  void refreshDataAfterUserLoaded() {
    getOrder();
  }

  getOrder() async {
    if (Constant.userModel != null) {
      FireStoreUtils.backendUserId = Constant.userModel!.id;
      if (kDebugMode) {
        log(
          '[OrderController] Set backendUserId to: ${Constant.userModel!.id}',
        );
      }
    }
    if (Constant.userModel != null) {
      if (kDebugMode) {
        log('[OrderController] User model exists, fetching orders...');
      }
      try {
        final orders = await FireStoreUtils.getAllOrder();
        if (kDebugMode) {
          log('[OrderController] Fetched ${orders.length} orders');
        }
        allList = orders;
        if (kDebugMode) {
          log('[OrderController] All orders: ${allList.length}');
        }
        newOrderList = allList
            .where(
              (p0) =>
                  p0.status == Constant.orderPlaced || p0.status == "pending",
            )
            .toList();
        rejectedList = allList
            .where((p0) => p0.status == Constant.orderRejected)
            .toList();
        inProgressList = allList
            .where(
              (p0) =>
                  p0.status == Constant.orderAccepted ||
                  p0.status == Constant.driverPending ||
                  p0.status == Constant.orderShipped ||
                  p0.status == Constant.orderInTransit,
            )
            .toList();
        deliveredList = allList
            .where((p0) => p0.status == Constant.orderCompleted)
            .toList();
        cancelledList = allList
            .where((p0) => p0.status == Constant.orderCancelled)
            .toList();
      } catch (e) {
        if (kDebugMode) {
          log('[OrderController] Error fetching orders: $e');
        }
      }
    } else {
      if (kDebugMode) {
        log('[OrderController] ERROR: Constant.userModel is null');
      }
    }
    isLoading = false;
    if (kDebugMode) {
      log('[OrderController] getOrder completed');
    }
    notifyListeners();
  }

  final CartProvider cartProvider = CartProvider();

  addToCart({required CartProductModel cartProductModel}) {
    cartProvider.addToCart(
      Get.context!,
      cartProductModel,
      cartProductModel.quantity!,
    );
    notifyListeners();
  }

  // Method to manually refresh orders (for debugging)
  Future<void> refreshOrders() async {
    log('[OrderController] Manual refresh requested');
    isLoading = true;
    await getOrder();
    notifyListeners();
  }

  // Method to force set the correct user ID (for debugging)
  void forceSetUserId() {
    if (Constant.userModel != null) {
      FireStoreUtils.backendUserId = Constant.userModel!.id;
      log(
        '[OrderController] Force set backendUserId to: ${Constant.userModel!.id}',
      );
    }
  }
}
