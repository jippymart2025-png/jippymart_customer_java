import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

// FireStoreUtils.fetchOrdersFromFirestorePage returns OrdersPageResult

/// Default page size for orders list (aligns with backend DEFAULT_PAGE_LIMIT).
const int kOrdersPageSize = 20;

class OrderProvider extends ChangeNotifier {
  List<OrderModel> allList = <OrderModel>[];
  List<OrderModel> newOrderList = <OrderModel>[];
  List<OrderModel> inProgressList = <OrderModel>[];
  List<OrderModel> deliveredList = <OrderModel>[];
  List<OrderModel> rejectedList = <OrderModel>[];
  List<OrderModel> cancelledList = <OrderModel>[];

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasNextPage = false;
  int _currentPage = 0;
  bool _isFetching = false;
  bool _hasQueuedForceRefresh = false;
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(minutes: 5);

  // Cache for order totals
  final Map<String, double> _orderTotalCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _refreshTimer;
  bool _initialized = false;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> initFunction() async {
    if (_initialized) return;
    _initialized = true;
    await getOrder();
    // Auto-refresh every 10 minutes
    _refreshTimer?.cancel();
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
      _updateLoadingState(false);
      return;
    }

    // Prevent concurrent fetches, but preserve explicit refresh intent.
    if (_isFetching) {
      if (forceRefresh) {
        _hasQueuedForceRefresh = true;
      }
      return;
    }
    _isFetching = true;

    if (Constant.userModel == null) {
      if (kDebugMode) {
        log('[OrderController] User not logged in');
      }
      _clearLists();
      _isFetching = false;
      _updateLoadingState(false);
      return;
    }

    try {
      FireStoreUtils.backendUserId = Constant.userModel?.firebaseId;
      if (kDebugMode) {
        log(
          '[OrderController] Set backendUserId to: ${Constant.userModel!.id}',
        );
      }

      _updateLoadingState(true);

      // Clear old cache if forcing refresh
      if (forceRefresh) {
        _orderTotalCache.clear();
        _cacheTimestamps.clear();
      }

      // Fetch first page (paginated API)
      final result =
          await FireStoreUtils.fetchOrdersFromFirestorePage(
            page: 1,
            limit: kOrdersPageSize,
            isRefresh: forceRefresh, // 🔥 THIS IS THE FIX
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              log('[OrderController] Order fetch timeout');
              return const OrdersPageResult(
                orders: [],
                pagination: OrdersPagination(
                  total: 0,
                  perPage: kOrdersPageSize,
                  currentPage: 1,
                  totalPages: 1,
                  hasNext: false,
                  hasPrev: false,
                ),
              );
            },
          );

      if (kDebugMode) {
        log(
          '[OrderController] Fetched ${result.orders.length} orders (page 1), hasNext=${result.pagination.hasNext}',
        );
      }

      _currentPage = 1;
      hasNextPage = result.pagination.hasNext;
      _processOrders(result.orders);

      _lastFetchTime = DateTime.now();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('[OrderController] Error fetching orders: $e');
        log('Stack trace: $stackTrace');
      }
      _handleError();
    } finally {
      _isFetching = false;
      _updateLoadingState(false);

      // If user requested refresh while a fetch was running, execute it now.
      if (_hasQueuedForceRefresh) {
        _hasQueuedForceRefresh = false;
        await getOrder(forceRefresh: true);
      }
    }
  }

  void _updateLoadingState(bool value) {
    if (isLoading == value) return;
    isLoading = value;
    notifyListeners();
  }

  void _processOrders(List<OrderModel> orders) {
    allList = orders;

    // FIXED: Case-insensitive status comparison with better null safety
    newOrderList = orders.where((order) {
      final status = order.status?.toString().trim().toLowerCase() ?? '';
      return status == 'order placed' || status == 'pending' || status == 'new';
    }).toList();

    rejectedList = orders.where((order) {
      final status = order.status?.toString().trim().toLowerCase() ?? '';
      return status == 'order rejected' ||
          status == 'rejected' ||
          status == 'order_rejected';
    }).toList();

    inProgressList = orders.where((order) {
      final status = order.status?.toString().trim().toLowerCase() ?? '';
      return status == 'order accepted' ||
          status == 'accepted' ||
          status == 'driver pending' ||
          status == 'order shipped' ||
          status == 'shipped' ||
          status == 'order in transit' ||
          status == 'in transit';
    }).toList();

    deliveredList = orders.where((order) {
      final status = order.status?.toString().trim().toLowerCase() ?? '';
      return status == 'order completed' ||
          status == 'completed' ||
          status == 'delivered';
    }).toList();

    cancelledList = orders.where((order) {
      final status = order.status?.toString().trim().toLowerCase() ?? '';
      return status == 'order cancelled' || status == 'cancelled';
    }).toList();
  }

  void _handleError() {
    allList = [];
    newOrderList = [];
    rejectedList = [];
    inProgressList = [];
    deliveredList = [];
    cancelledList = [];
    _currentPage = 0;
    hasNextPage = false;
  }

  void _clearLists() {
    allList = [];
    newOrderList = [];
    rejectedList = [];
    inProgressList = [];
    deliveredList = [];
    cancelledList = [];
    _currentPage = 0;
    hasNextPage = false;
  }

  /// Loads the next page of orders and appends to lists. No-op if no next page or already loading.
  Future<void> loadMoreOrders() async {
    if (!hasNextPage || isLoadingMore || _isFetching) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result =
          await FireStoreUtils.fetchOrdersFromFirestorePage(
            page: nextPage,
            limit: kOrdersPageSize,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () => const OrdersPageResult(
              orders: [],
              pagination: OrdersPagination(
                total: 0,
                perPage: kOrdersPageSize,
                currentPage: 1,
                totalPages: 1,
                hasNext: false,
                hasPrev: false,
              ),
            ),
          );

      if (result.orders.isEmpty) {
        hasNextPage = false;
      } else {
        _currentPage = nextPage;
        hasNextPage = result.pagination.hasNext;
        final merged = List<OrderModel>.from(allList)..addAll(result.orders);
        merged.sort((a, b) {
          final aTs = a.createdAt;
          final bTs = b.createdAt;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
        _processOrders(merged);
      }
      if (kDebugMode) {
        log(
          '[OrderController] Loaded more: +${result.orders.length}, total=${allList.length}, hasNext=$hasNextPage',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        log('[OrderController] loadMoreOrders error: $e');
        log('Stack: $st');
      }
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
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

      final live = await FireStoreUtils.getCurrentProductPrice(
        productId: cartProductModel.id ?? '',
        vendorId: cartProductModel.vendorID ?? '',
        variantInfo: cartProductModel.variantInfo,
        vendorModel: VendorModel(id: cartProductModel.vendorID),
        fallbackPrice: cartProductModel.price,
        fallbackDiscountPrice: cartProductModel.discountPrice,
        forceRefresh: true,
      );

      CartProductModel productToAdd;
      if (live != null) {
        productToAdd = CartProductModel(
          id: cartProductModel.id,
          name: cartProductModel.name,
          photo: cartProductModel.photo,
          price: live.currentPrice.toStringAsFixed(2),
          discountPrice: live.discountPrice.toStringAsFixed(2),
          promoId: live.promoId ?? cartProductModel.promoId,
          quantity: cartProductModel.quantity,
          vendorID: cartProductModel.vendorID,
          categoryId: cartProductModel.categoryId,
          merchantPrice: cartProductModel.merchantPrice,
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

  bool _isMartOrderLine(CartProductModel element) {
    final vid = element.vendorID ?? '';
    return vid.startsWith('demo_') ||
        vid.contains('mart') ||
        vid.contains('vendor');
  }

  bool _isLiveFoodProductReorderable(ProductModel? product) {
    if (product == null) return false;
    return product.publish != false && product.isAvailable != false;
  }

  /// Reorder all items from an order (batched live catalog fetch, variant-aware prices).
  // Future<void> reorderOrder(OrderModel order, BuildContext context) async {
  //   if (order.products == null || order.products!.isEmpty) {
  //     ShowToastDialog.showToast("No items to reorder".tr);
  //     return;
  //   }
  //
  //   ShowToastDialog.showLoader("Fetching current prices...".tr);
  //
  //   try {
  //     int addedCount = 0;
  //     int failedCount = 0;
  //     int unavailableCount = 0;
  //     final vendor = order.vendor;
  //     final lines = order.products!;
  //
  //     final foodCatalogIds = <String>{};
  //     for (final e in lines) {
  //       if (_isMartOrderLine(e)) continue;
  //       final cid = FireStoreUtils.catalogIdFromOrderLine(e.id);
  //       if (cid.isNotEmpty) foodCatalogIds.add(cid);
  //     }
  //
  //     var foodByCatalogId = <String, ProductModel?>{};
  //     if (foodCatalogIds.isNotEmpty) {
  //       foodByCatalogId = await FireStoreUtils.getProductsByIds(
  //         foodCatalogIds.toList(),
  //         forceRefresh: true,
  //       );
  //     }
  //
  //     for (final element in lines) {
  //       try {
  //         final isMartLine = _isMartOrderLine(element);
  //         ProductModel? p;
  //         if (!isMartLine) {
  //           final cid = FireStoreUtils.catalogIdFromOrderLine(element.id);
  //           if (cid.isEmpty) {
  //             unavailableCount++;
  //             continue;
  //           }
  //           p = foodByCatalogId[cid];
  //           if (!_isLiveFoodProductReorderable(p)) {
  //             unavailableCount++;
  //             continue;
  //           }
  //         }
  //
  //         var info = FireStoreUtils.priceInfoForReorderLine(
  //           product: p,
  //           element: element,
  //           vendor: vendor,
  //         );
  //         if (info == null && isMartLine) {
  //           info = FireStoreUtils.priceInfoForReorderLine(
  //             product: null,
  //             element: element,
  //             vendor: vendor,
  //           );
  //         }
  //
  //         if (info == null) {
  //           unavailableCount++;
  //           continue;
  //         }
  //
  //         final productToAdd = CartProductModel(
  //           id: element.id,
  //           name: element.name,
  //           photo: element.photo,
  //           price: info.currentPrice.toStringAsFixed(2),
  //           discountPrice: info.discountPrice.toStringAsFixed(2),
  //           promoId: info.promoId ?? element.promoId,
  //           quantity: element.quantity ?? 1,
  //           vendorID: element.vendorID,
  //           categoryId: element.categoryId,
  //           merchantPrice: info.merchantPrice ?? element.merchantPrice,
  //           extrasPrice: element.extrasPrice,
  //           extras: element.extras,
  //           variantInfo: element.variantInfo,
  //         );
  //
  //         await addToCartWithLivePrices(
  //           cartProductModel: productToAdd,
  //           context: context,
  //         );
  //         addedCount++;
  //       } catch (e) {
  //         failedCount++;
  //         log('Error adding item ${element.id}: $e');
  //       }
  //     }
  //
  //     ShowToastDialog.closeLoader();
  //
  //     if (addedCount > 0 && unavailableCount == 0 && failedCount == 0) {
  //       ShowToastDialog.showToast("$addedCount item(s) added to cart".tr);
  //     } else if (addedCount > 0) {
  //       final parts = <String>["$addedCount item(s) added to cart".tr];
  //       if (unavailableCount > 0) {
  //         parts.add(
  //           "$unavailableCount item(s) were no longer available and were skipped"
  //               .tr,
  //         );
  //       }
  //       if (failedCount > 0) {
  //         parts.add("$failedCount item(s) could not be added".tr);
  //       }
  //       ShowToastDialog.showToast(parts.join(". "));
  //     } else if (unavailableCount > 0 && failedCount == 0) {
  //       ShowToastDialog.showToast("These items are no longer available".tr);
  //     } else if (failedCount > 0) {
  //       ShowToastDialog.showToast(
  //         "$failedCount item(s) could not be added. Please try again.".tr,
  //       );
  //     }
  //   } catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast("Error fetching current prices".tr);
  //   }
  // }

  Future<void> reorderOrder(OrderModel order, BuildContext context) async {
    if (order.products == null || order.products!.isEmpty) {
      ShowToastDialog.showToast("No items to reorder".tr);
      return;
    }

    ShowToastDialog.showLoader("Fetching current prices...".tr);

    try {
      int addedCount = 0;
      int failedCount = 0;
      int unavailableCount = 0;

      final vendor = order.vendor;
      final lines = order.products!;

      /// Fetch all food products first
      final foodCatalogIds = <String>{};

      for (final e in lines) {
        if (_isMartOrderLine(e)) continue;

        final cid = FireStoreUtils.catalogIdFromOrderLine(e.id);

        if (cid.isNotEmpty) {
          foodCatalogIds.add(cid);
        }
      }

      Map<String, ProductModel?> foodByCatalogId = {};

      if (foodCatalogIds.isNotEmpty) {
        foodByCatalogId = await FireStoreUtils.getProductsByIds(
          foodCatalogIds.toList(),
          forceRefresh: true,
        );
      }

      /// Process each order item
      for (final element in lines) {
        try {
          final isMartLine = _isMartOrderLine(element);

          ProductModel? product;

          if (!isMartLine) {
            final cid = FireStoreUtils.catalogIdFromOrderLine(element.id);

            if (cid.isEmpty) {
              unavailableCount++;
              continue;
            }

            product = foodByCatalogId[cid];

            /// Product exists check
            if (product == null) {
              unavailableCount++;
              continue;
            }

            /// Existing reorder validation
            if (!_isLiveFoodProductReorderable(product)) {
              unavailableCount++;
              continue;
            }

            /// Available days + timing check
            if (!isProductAvailableNow(product)) {
              unavailableCount++;
              continue;
            }
          }

          /// Get latest pricing info
          var info = FireStoreUtils.priceInfoForReorderLine(
            product: product,
            element: element,
            vendor: vendor,
          );

          if (info == null && isMartLine) {
            info = FireStoreUtils.priceInfoForReorderLine(
              product: null,
              element: element,
              vendor: vendor,
            );
          }

          if (info == null) {
            unavailableCount++;
            continue;
          }

          /// Create cart item
          final productToAdd = CartProductModel(
            id: element.id,
            name: element.name,
            photo: element.photo,
            price: info.currentPrice.toStringAsFixed(2),
            discountPrice: info.discountPrice.toStringAsFixed(2),
            promoId: info.promoId ?? element.promoId,
            quantity: element.quantity ?? 1,
            vendorID: element.vendorID,
            categoryId: element.categoryId,
            merchantPrice: info.merchantPrice ?? element.merchantPrice,
            extrasPrice: element.extrasPrice,
            extras: element.extras,
            variantInfo: element.variantInfo,
          );

          /// Add to cart
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

      /// Result messages
      if (addedCount > 0 && unavailableCount == 0 && failedCount == 0) {
        ShowToastDialog.showToast("$addedCount item(s) added to cart".tr);
      } else if (addedCount > 0) {
        final parts = <String>["$addedCount item(s) added to cart".tr];

        if (unavailableCount > 0) {
          parts.add(
            "$unavailableCount item(s) were no longer available and were skipped"
                .tr,
          );
        }

        if (failedCount > 0) {
          parts.add("$failedCount item(s) could not be added".tr);
        }

        ShowToastDialog.showToast(parts.join(". "));
      } else if (unavailableCount > 0 && failedCount == 0) {
        ShowToastDialog.showToast("These items are currently unavailable".tr);
      } else if (failedCount > 0) {
        ShowToastDialog.showToast(
          "$failedCount item(s) could not be added. Please try again.".tr,
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();

      log("Reorder error: $e");

      ShowToastDialog.showToast("Error fetching current prices".tr);
    }
  }

  bool isProductAvailableNow(ProductModel? product) {
    if (product == null) return false;

    try {
      final now = DateTime.now();

      final currentDay = DateFormat('EEEE').format(now);

      final timings = product.availableTimings;

      if (timings == null || timings.isEmpty) {
        return true;
      }

      ProductAvailabilitySchedule? todaySchedule;

      for (final item in timings) {
        if ((item.day ?? '').toLowerCase() == currentDay.toLowerCase()) {
          todaySchedule = item;
          break;
        }
      }

      if (todaySchedule == null) {
        return false;
      }

      final slots = todaySchedule.timeslot ?? [];

      if (slots.isEmpty) {
        return false;
      }

      for (final slot in slots) {
        final from = slot.from;
        final to = slot.to;

        if (from == null || to == null) continue;

        final fromParts = from.split(":");
        final toParts = to.split(":");

        final fromTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(fromParts[0]),
          int.parse(fromParts[1]),
        );

        final toTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(toParts[0]),
          int.parse(toParts[1]),
        );

        log("NOW => $now");
        log("FROM => $fromTime");
        log("TO => $toTime");

        if (!now.isBefore(fromTime) && !now.isAfter(toTime)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      log("Availability timing error: $e");
      return false;
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

  // FIXED: Added method to get count of rejected orders for debugging
  int getRejectedCount() {
    return rejectedList.length;
  }

  // FIXED: Added method to debug print all statuses
  void debugPrintAllStatuses() {
    log('===== ORDER STATUS DEBUG =====');
    for (var order in allList) {
      log('Order ${order.id}: status = "${order.status}"');
    }
    log('==============================');
  }
}
