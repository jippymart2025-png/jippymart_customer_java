import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
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
  bool _isFetching = false;
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(minutes: 5);

  // Cache for order totals
  final Map<String, double> _orderTotalCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> initFunction() async {
    await getOrder();
    // Auto-refresh every 10 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (Constant.userModel != null) {
        getOrder(forceRefresh: true);
      }
    });
  }

  void refreshDataAfterUserLoaded() {
    getOrder(forceRefresh: true);
  }

  Future<void> getOrder({bool forceRefresh = false}) async {
    // Check cache validity
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      if (kDebugMode) {
        log('[OrderController] Using cached orders');
      }
      isLoading = false;
      notifyListeners();
      return;
    }

    // Prevent concurrent fetches
    if (_isFetching) return;
    _isFetching = true;

    if (Constant.userModel == null) {
      if (kDebugMode) {
        log('[OrderController] User not logged in');
      }
      _clearLists();
      _isFetching = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      FireStoreUtils.backendUserId = Constant.userModel?.firebaseId;
      if (kDebugMode) {
        log(
          '[OrderController] Set backendUserId to: ${Constant.userModel!.id}',
        );
      }

      isLoading = true;
      notifyListeners();

      // Clear old cache if forcing refresh
      if (forceRefresh) {
        _orderTotalCache.clear();
        _cacheTimestamps.clear();
      }

      // Fetch orders with timeout
      final orders = await FireStoreUtils.getAllOrder().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          log('[OrderController] Order fetch timeout');
          return <OrderModel>[];
        },
      );

      if (kDebugMode) {
        log('[OrderController] Fetched ${orders.length} orders');
      }

      // Process orders
      _processOrders(orders);

      _lastFetchTime = DateTime.now();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('[OrderController] Error fetching orders: $e');
        log('Stack trace: $stackTrace');
      }
      _handleError();
    } finally {
      _isFetching = false;
      isLoading = false;
      notifyListeners();
    }
  }

  void _processOrders(List<OrderModel> orders) {
    allList = orders;

    // Efficient filtering with null safety
    newOrderList = orders.where((order) {
      final status = order.status?.toLowerCase();
      return status == Constant.orderPlaced?.toLowerCase() ||
          status == "pending";
    }).toList();

    rejectedList = orders.where((order) {
      final status = order.status?.toLowerCase();
      return status == Constant.orderRejected?.toLowerCase();
    }).toList();

    inProgressList = orders.where((order) {
      final status = order.status?.toLowerCase();
      return status == Constant.orderAccepted?.toLowerCase() ||
          status == Constant.driverPending?.toLowerCase() ||
          status == Constant.orderShipped?.toLowerCase() ||
          status == Constant.orderInTransit?.toLowerCase();
    }).toList();

    deliveredList = orders.where((order) {
      final status = order.status?.toLowerCase();
      return status == Constant.orderCompleted?.toLowerCase();
    }).toList();

    cancelledList = orders.where((order) {
      final status = order.status?.toLowerCase();
      return status == Constant.orderCancelled?.toLowerCase();
    }).toList();
  }

  void _handleError() {
    allList = [];
    newOrderList = [];
    rejectedList = [];
    inProgressList = [];
    deliveredList = [];
    cancelledList = [];
  }

  void _clearLists() {
    allList = [];
    newOrderList = [];
    rejectedList = [];
    inProgressList = [];
    deliveredList = [];
    cancelledList = [];
  }

  // Cache order totals to avoid recalculation
  Future<double> getCachedOrderTotal(OrderModel order) async {
    final cacheKey = '${order.id}_total';

    // Check cache
    if (_orderTotalCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return _orderTotalCache[cacheKey]!;
      }
    }

    // Calculate and cache
    final total = await _calculateOrderTotal(order);
    _orderTotalCache[cacheKey] = total;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return total;
  }

  Future<double> _calculateOrderTotal(OrderModel order) async {
    try {
      double subTotal = 0.0;
      double specialDiscountAmount = 0.0;
      double taxAmount = 0.0;

      if (order.products != null) {
        for (var element in order.products!) {
          final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
          final discountPriceValue =
              double.tryParse(element.discountPrice.toString()) ?? 0.0;

          double itemPrice;
          if (discountPriceValue <= 0) {
            itemPrice = priceValue;
          } else {
            itemPrice = discountPriceValue;
          }

          final quantity = double.parse(element.quantity.toString());
          final extrasPrice = double.parse(element.extrasPrice.toString());
          final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
          subTotal += itemTotal;
        }
      }

      if (order.specialDiscount != null &&
          order.specialDiscount!['special_discount'] != null) {
        specialDiscountAmount =
            double.tryParse(
              order.specialDiscount!['special_discount'].toString(),
            ) ??
            0.0;
      }

      double sgst = 0.0;
      double gst = 0.0;
      if (order.taxSetting != null) {
        for (var element in order.taxSetting!) {
          try {
            if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
              sgst = Constant.calculateTax(
                amount: subTotal.toString(),
                taxModel: element,
              );
            } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
              gst = Constant.calculateTax(
                amount: double.parse(
                  order.deliveryCharge.toString(),
                ).toString(),
                taxModel: element,
              );
            }
          } catch (e) {
            log('Error processing tax element: $e');
          }
        }
      }
      taxAmount = sgst + gst;

      final totalAmount =
          (subTotal - (order.discount ?? 0.0) - specialDiscountAmount) +
          taxAmount +
          (double.tryParse(order.deliveryCharge?.toString() ?? '0.0') ?? 0.0) +
          (double.tryParse(order.tipAmount?.toString() ?? '0.0') ?? 0.0);

      return totalAmount;
    } catch (e) {
      log('Error calculating order total: $e');
      return order.toPayAmount?.toDouble() ?? 0.0;
    }
  }

  /// Add to cart with pre-fetched live prices (used by reorder - no re-fetch)
  Future<void> addToCartWithLivePrices({
    required CartProductModel cartProductModel,
    BuildContext? context,
  }) async {
    try {
      final cartProvider = CartProvider();
      final quantity = cartProductModel.quantity ?? 1;
      final ctx = context ?? Get.context;
      if (ctx == null) {
        log('Error in addToCartWithLivePrices: No context available');
        return;
      }
      await cartProvider.addToCart(ctx, cartProductModel, quantity);
      notifyListeners();
    } catch (e) {
      log('Error in addToCartWithLivePrices: $e');
      rethrow;
    }
  }

  /// Add to cart - fetches current price before adding (for other flows)
  Future<void> addToCart({
    required CartProductModel cartProductModel,
    BuildContext? context,
  }) async {
    try {
      final cartProvider = CartProvider();

      final currentProduct = await FireStoreUtils.getCurrentProductPrice(
        productId: cartProductModel.id ?? '',
        vendorId: cartProductModel.vendorID ?? '',
      );

      CartProductModel productToAdd;
      if (currentProduct != null) {
        productToAdd = CartProductModel(
          id: cartProductModel.id,
          name: cartProductModel.name,
          photo: cartProductModel.photo,
          price: currentProduct.currentPrice.toString(),
          discountPrice: currentProduct.discountPrice.toString(),
          promoId: currentProduct.promoId,
          quantity: cartProductModel.quantity,
          vendorID: cartProductModel.vendorID,
          categoryId: cartProductModel.categoryId,
          extrasPrice: cartProductModel.extrasPrice,
          extras: cartProductModel.extras,
          variantInfo: cartProductModel.variantInfo,
        );
      } else {
        productToAdd = cartProductModel;
      }

      final ctx = context ?? Get.context;
      if (ctx == null) {
        log('Error in addToCart: No context available');
        return;
      }
      await cartProvider.addToCart(
        ctx,
        productToAdd,
        productToAdd.quantity ?? 1,
      );

      notifyListeners();
    } catch (e) {
      log('Error in addToCart: $e');
      rethrow;
    }
  }

  /// Reorder all items from an order (fetches live prices, fallback to order prices)
  Future<void> reorderOrder(OrderModel order, BuildContext context) async {
    if (order.products == null || order.products!.isEmpty) {
      ShowToastDialog.showToast("No items to reorder".tr);
      return;
    }

    ShowToastDialog.showLoader("Fetching current prices...".tr);

    try {
      int addedCount = 0;
      int failedCount = 0;

      for (var element in order.products!) {
        try {
          final currentProduct = await FireStoreUtils.getCurrentProductPrice(
            productId: element.id ?? '',
            vendorId: element.vendorID ?? '',
          );

          final CartProductModel productToAdd;
          if (currentProduct != null) {
            productToAdd = CartProductModel(
              id: element.id,
              name: element.name,
              photo: element.photo,
              price: currentProduct.currentPrice.toString(),
              discountPrice: currentProduct.discountPrice.toString(),
              promoId: currentProduct.promoId,
              quantity: element.quantity ?? 1,
              vendorID: element.vendorID,
              categoryId: element.categoryId,
              extrasPrice: element.extrasPrice,
              extras: element.extras,
              variantInfo: element.variantInfo,
            );
          } else {
            productToAdd = CartProductModel(
              id: element.id,
              name: element.name,
              photo: element.photo,
              price: element.price?.toString() ?? '0',
              discountPrice: element.discountPrice?.toString() ?? '0',
              promoId: element.promoId,
              quantity: element.quantity ?? 1,
              vendorID: element.vendorID,
              categoryId: element.categoryId,
              extrasPrice: element.extrasPrice,
              extras: element.extras,
              variantInfo: element.variantInfo,
            );
          }

          await addToCartWithLivePrices(
            cartProductModel: productToAdd,
            context: context,
          );
          addedCount++;
        } catch (e) {
          failedCount++;
          log('Error adding item ${element.id}: $e');
        }
      }

      ShowToastDialog.closeLoader();

      if (addedCount > 0) {
        ShowToastDialog.showToast("$addedCount item(s) added to cart".tr);
      }

      if (failedCount > 0) {
        ShowToastDialog.showToast(
          "$failedCount item(s) could not be added. Please try again.".tr,
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error fetching current prices".tr);
    }
  }

  // Method to manually refresh orders
  Future<void> refreshOrders() async {
    log('[OrderController] Manual refresh requested');
    await getOrder(forceRefresh: true);
  }

  // Clear cache when needed
  void clearCache() {
    _orderTotalCache.clear();
    _cacheTimestamps.clear();
    _lastFetchTime = null;
  }

  // Get only specific order for details view
  Future<OrderModel?> getOrderById(String orderId) async {
    // Check cache first
    final cachedOrder = allList.firstWhere(
      (order) => order.id == orderId,
      orElse: () => OrderModel(),
    );

    if (cachedOrder.id != null) {
      return cachedOrder;
    }

    // Fetch single order
    return await FireStoreUtils.getOrderById(orderId);
  }

  // Method to force set the correct user ID
  void forceSetUserId() {
    if (Constant.userModel != null) {
      FireStoreUtils.backendUserId = Constant.userModel!.id;
      log(
        '[OrderController] Force set backendUserId to: ${Constant.userModel!.id}',
      );
    }
  }
}
