import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/app/chat_screens/chat_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/rate_us_screen/provider/rate_product_provider.dart';
import 'package:jippymart_customer/app/rate_us_screen/rate_product_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

class OrderBillDetails {
  final double subTotal;
  final double deliveryCharges;
  final double originalDeliveryFee;
  final double couponAmount;
  final double specialDiscountAmount;
  final double taxAmount;
  final double deliveryTips;
  final double totalAmount;
  final bool isFreeDelivery;

  OrderBillDetails({
    required this.subTotal,
    required this.deliveryCharges,
    required this.originalDeliveryFee,
    required this.couponAmount,
    required this.specialDiscountAmount,
    required this.taxAmount,
    required this.deliveryTips,
    required this.totalAmount,
    required this.isFreeDelivery,
  });
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, this.surgeFee});

  final double? surgeFee;

  // Cache for promotional details to avoid repeated Firestore calls
  static final Map<String, Map<String, dynamic>> _promoDetailsCache = {};

  // Cached delivery charge fetched from backend (mirrors cart provider behaviour)
  static DeliveryCharge? _cachedMartDeliveryCharge;
  static DateTime? _lastDeliveryChargeFetchTime;
  static const Duration _deliveryChargeCacheExpiry = Duration(minutes: 5);

  // Fallback values used only when API data is unavailable
  static const double _fallbackThreshold = 299.0;
  static const double _fallbackBaseCharge = 23.0;
  static const double _fallbackFreeKm = 5.0;
  static const double _fallbackPerKm = 7.0;
  static const double _promoFreeDeliveryKm = 3.0;

  Future<OrderBillDetails> _calculateOrderBillDetails(
    OrderModel order,
    VendorModel? vendor,
    DeliveryCharge deliveryCharge,
    double totalDistance,
  ) async {
    final DeliveryCharge resolvedDeliveryCharge = await _resolveDeliveryCharge(
      deliveryCharge,
      vendor: vendor,
    );

    // Calculate subtotal first (local calculation)
    final subTotalResult = _calculateSubTotal(order);
    final double subTotal = subTotalResult['subTotal'] as double;
    final bool hasPromotionalItems =
        subTotalResult['hasPromotionalItems'] as bool;

    final double threshold = _getDoubleValue(
      resolvedDeliveryCharge.itemTotalThreshold,
      _fallbackThreshold,
    );
    final double baseCharge = _getDoubleValue(
      resolvedDeliveryCharge.baseDeliveryCharge,
      _fallbackBaseCharge,
    );
    final double freeKm = _getDoubleValue(
      resolvedDeliveryCharge.freeDeliveryDistanceKm,
      _fallbackFreeKm,
    );
    final double perKm = _getDoubleValue(
      resolvedDeliveryCharge.perKmChargeAboveFreeDistance,
      _fallbackPerKm,
    );

    // Delivery charges calculation
    final deliveryResult = await _calculateDeliveryCharges(
      order: order,
      vendor: vendor,
      hasPromotionalItems: hasPromotionalItems,
      subTotal: subTotal,
      totalDistance: totalDistance,
      threshold: threshold,
      baseCharge: baseCharge,
      freeKm: freeKm,
      perKm: perKm,
    );

    // Coupon calculation
    final double couponAmount = _calculateCouponAmount(
      order: order,
      hasPromotionalItems: hasPromotionalItems,
    );

    // Special discount
    final double specialDiscountAmount = _calculateSpecialDiscount(order);

    // Tax calculation
    final double taxAmount = _calculateTaxAmount(
      subTotal: subTotal,
      deliveryCharges: deliveryResult['deliveryCharges'] as double,
      originalDeliveryFee: deliveryResult['originalDeliveryFee'] as double,
    );

    // Check free delivery
    final bool isFreeDelivery = _checkFreeDelivery(
      hasPromotionalItems: hasPromotionalItems,
      subTotal: subTotal,
      totalDistance: totalDistance,
      threshold: threshold,
      freeKm: freeKm,
    );

    // Delivery tips
    final double deliveryTips = _getDoubleValue(order.tipAmount, 0.0);

    // Total amount
    final double totalAmount =
        (subTotal - couponAmount - specialDiscountAmount) +
        taxAmount +
        (isFreeDelivery ? 0.0 : deliveryResult['deliveryCharges'] as double) +
        deliveryTips;

    return OrderBillDetails(
      subTotal: subTotal,
      deliveryCharges: deliveryResult['deliveryCharges'] as double,
      originalDeliveryFee: deliveryResult['originalDeliveryFee'] as double,
      couponAmount: couponAmount,
      specialDiscountAmount: specialDiscountAmount,
      taxAmount: taxAmount,
      deliveryTips: deliveryTips,
      totalAmount: totalAmount,
      isFreeDelivery: isFreeDelivery,
    );
  }

  Future<DeliveryCharge> _resolveDeliveryCharge(
    DeliveryCharge deliveryCharge, {
    VendorModel? vendor,
  }) async {
    if (_hasDeliveryChargeData(deliveryCharge)) {
      return deliveryCharge;
    }

    if (_cachedMartDeliveryCharge != null && _isDeliveryChargeCacheValid()) {
      vendor?.deliveryCharge ??= _cachedMartDeliveryCharge;
      return _cachedMartDeliveryCharge!;
    }

    final apiDeliveryCharge = await FireStoreUtils.getDeliveryCharge();
    if (_hasDeliveryChargeData(apiDeliveryCharge)) {
      _cachedMartDeliveryCharge = apiDeliveryCharge;
      _lastDeliveryChargeFetchTime = DateTime.now();
      vendor?.deliveryCharge = apiDeliveryCharge;
      return apiDeliveryCharge!;
    }

    final fallbackCharge = DeliveryCharge(
      itemTotalThreshold: _fallbackThreshold,
      baseDeliveryCharge: _fallbackBaseCharge,
      freeDeliveryDistanceKm: _fallbackFreeKm,
      perKmChargeAboveFreeDistance: _fallbackPerKm,
    );
    vendor?.deliveryCharge ??= fallbackCharge;
    return fallbackCharge;
  }

  bool _hasDeliveryChargeData(DeliveryCharge? charge) {
    if (charge == null) {
      return false;
    }

    final hasThreshold =
        charge.itemTotalThreshold != null && charge.itemTotalThreshold! > 0;
    final hasBaseCharge =
        charge.baseDeliveryCharge != null && charge.baseDeliveryCharge! > 0;
    final hasFreeKm =
        charge.freeDeliveryDistanceKm != null &&
        charge.freeDeliveryDistanceKm! > 0;
    final hasPerKm =
        charge.perKmChargeAboveFreeDistance != null &&
        charge.perKmChargeAboveFreeDistance! > 0;

    return hasThreshold || hasBaseCharge || hasFreeKm || hasPerKm;
  }

  bool _isDeliveryChargeCacheValid() {
    if (_lastDeliveryChargeFetchTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastDeliveryChargeFetchTime!) <
        _deliveryChargeCacheExpiry;
  }

  double _getDoubleValue(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> _calculateSubTotal(OrderModel order) {
    double subTotal = 0.0;
    bool hasPromotionalItems = false;

    if (order.products != null) {
      for (var element in order.products!) {
        final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
        final discountPriceValue =
            double.tryParse(element.discountPrice.toString()) ?? 0.0;

        // Check if promotional
        final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
        final isPricePromotional =
            priceValue > 0 &&
            discountPriceValue > 0 &&
            priceValue < discountPriceValue;
        final isPromotional = hasPromo || isPricePromotional;

        if (isPromotional) {
          hasPromotionalItems = true;
        }

        double itemPrice;
        if (isPromotional) {
          itemPrice = priceValue < discountPriceValue
              ? priceValue
              : discountPriceValue;
        } else if (discountPriceValue <= 0) {
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

    return {'subTotal': subTotal, 'hasPromotionalItems': hasPromotionalItems};
  }

  Future<Map<String, double>> _calculateDeliveryCharges({
    required OrderModel order,
    required VendorModel? vendor,
    required bool hasPromotionalItems,
    required double subTotal,
    required double totalDistance,
    required double threshold,
    required double baseCharge,
    required double freeKm,
    required double perKm,
  }) async {
    double deliveryCharges = 0.0;
    double originalDeliveryFee = 0.0;

    // Self delivery check
    if (vendor?.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      return {'deliveryCharges': 0.0, 'originalDeliveryFee': 0.0};
    }

    if (hasPromotionalItems) {
      // Promotional items delivery logic
      final promotionalItems = (order.products ?? []).where((item) {
        final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
        final discountPriceValue =
            double.tryParse(item.discountPrice.toString()) ?? 0.0;
        final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
        final isPricePromotional =
            priceValue > 0 &&
            discountPriceValue > 0 &&
            priceValue < discountPriceValue;
        return hasPromo || isPricePromotional;
      }).toList();

      if (promotionalItems.isNotEmpty) {
        final firstPromoItem = promotionalItems.first;
        final cacheKey = '${firstPromoItem.id}_${firstPromoItem.vendorID}';

        try {
          // Check cache first
          Map<String, dynamic>? promoDetails;
          if (_promoDetailsCache.containsKey(cacheKey)) {
            promoDetails = _promoDetailsCache[cacheKey];
          } else {
            // Fetch from Firestore if not in cache
            promoDetails = await FireStoreUtils.getActivePromotionForProduct(
              productId: firstPromoItem.id ?? '',
              restaurantId: firstPromoItem.vendorID ?? '',
            );
            if (promoDetails != null) {
              _promoDetailsCache[cacheKey] = promoDetails;
            }
          }

          if (promoDetails != null) {
            final freeDeliveryKm = _getDoubleValue(
              promoDetails['free_delivery_km'],
              3.0,
            );
            final extraKmCharge = _getDoubleValue(
              promoDetails['extra_km_charge'],
              perKm,
            );

            if (totalDistance <= freeDeliveryKm) {
              deliveryCharges = 0.0;
              originalDeliveryFee = baseCharge;
            } else {
              // 🔑 FIX: For promotional items above free km, GST should be on base charge + extra km charges
              double extraKm = (totalDistance - freeDeliveryKm).ceilToDouble();
              deliveryCharges = extraKm * extraKmCharge;
              originalDeliveryFee =
                  baseCharge +
                  deliveryCharges; // Base charge + extra km for GST
            }
            return {
              'deliveryCharges': deliveryCharges,
              'originalDeliveryFee': originalDeliveryFee,
            };
          }
        } catch (e) {
          // Fall through to regular logic
        }
      }
    }

    // Regular delivery logic (fallback)
    if (subTotal < threshold) {
      if (totalDistance <= freeKm) {
        deliveryCharges = baseCharge;
        originalDeliveryFee = baseCharge;
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        deliveryCharges = baseCharge + (extraKm * perKm);
        originalDeliveryFee = deliveryCharges;
      }
    } else {
      if (totalDistance <= freeKm) {
        deliveryCharges = 0.0;
        originalDeliveryFee = baseCharge;
      } else {
        double extraKm = (totalDistance - freeKm).ceilToDouble();
        deliveryCharges = extraKm * perKm;
        originalDeliveryFee = baseCharge + (extraKm * perKm);
      }
    }

    return {
      'deliveryCharges': deliveryCharges,
      'originalDeliveryFee': originalDeliveryFee,
    };
  }

  double _calculateCouponAmount({
    required OrderModel order,
    required bool hasPromotionalItems,
  }) {
    if (hasPromotionalItems) {
      return 0.0;
    }

    if (order.couponId != null &&
        order.couponId!.isNotEmpty &&
        order.discount != null) {
      return _getDoubleValue(order.discount, 0.0);
    }

    return 0.0;
  }

  double _calculateSpecialDiscount(OrderModel order) {
    if (order.specialDiscount != null &&
        order.specialDiscount!['special_discount'] != null) {
      return _getDoubleValue(order.specialDiscount!['special_discount'], 0.0);
    }
    return 0.0;
  }

  double _calculateTaxAmount({
    required double subTotal,
    required double deliveryCharges,
    required double originalDeliveryFee,
  }) {
    final double taxableDeliveryFee = originalDeliveryFee > 0
        ? originalDeliveryFee
        : (deliveryCharges > 0 ? deliveryCharges : 0.0);

    double sgst = subTotal * 0.05;
    double gst = taxableDeliveryFee * 0.18;
    sgst = sgst.isNaN ? 0.0 : sgst;
    gst = gst.isNaN ? 0.0 : gst;

    double taxAmount = sgst + gst;

    if (taxAmount == 0.0) {
      double sgstFallback = subTotal * 0.05;
      double gstFallback = taxableDeliveryFee > 0
          ? taxableDeliveryFee * 0.18
          : 0.0;
      taxAmount = sgstFallback + gstFallback;
    }

    return taxAmount.isNaN ? 0.0 : taxAmount;
  }

  bool _checkFreeDelivery({
    required bool hasPromotionalItems,
    required double subTotal,
    required double totalDistance,
    required double threshold,
    required double freeKm,
  }) {
    if (hasPromotionalItems) {
      // For promotional items, free delivery within 3km (or use cache)
      return totalDistance <= 3.0;
    } else {
      // For regular items
      return subTotal >= threshold && totalDistance <= freeKm;
    }
  }

  // Optimized widget builder for product item
  Widget _buildProductItem(
    BuildContext context,
    CartProductModel cartProductModel,
  ) {
    final priceValue =
        double.tryParse(cartProductModel.price.toString()) ?? 0.0;
    final discountPriceValue =
        double.tryParse(cartProductModel.discountPrice.toString()) ?? 0.0;
    final hasPromo =
        cartProductModel.promoId != null &&
        cartProductModel.promoId!.isNotEmpty;
    final isPricePromotional =
        priceValue > 0 &&
        discountPriceValue > 0 &&
        priceValue < discountPriceValue;
    final isPromotional = hasPromo || isPricePromotional;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProductImage(context, cartProductModel),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${cartProductModel.name}",
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.grey900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        "x ${cartProductModel.quantity}",
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  _buildPriceWidget(isPromotional, cartProductModel),
                  _buildRateButton(context, cartProductModel),
                ],
              ),
            ),
          ],
        ),
        _buildVariants(cartProductModel),
        _buildExtras(cartProductModel),
      ],
    );
  }

  Widget _buildProductImage(
    BuildContext context,
    CartProductModel cartProductModel,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Stack(
        children: [
          NetworkImageWidget(
            imageUrl: cartProductModel.photo.toString(),
            height: Responsive.height(8, context),
            width: Responsive.width(16, context),
            fit: BoxFit.cover,
            fixOrientation: true,
          ),
          Container(
            height: Responsive.height(8, context),
            width: Responsive.width(16, context),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.00, -1.00),
                end: const Alignment(0, 1),
                colors: [Colors.black.withOpacity(0), const Color(0xFF111827)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceWidget(
    bool isPromotional,
    CartProductModel cartProductModel,
  ) {
    if (isPromotional) {
      return Row(
        children: [
          Text(
            Constant.amountShow(amount: cartProductModel.price.toString()),
            style: TextStyle(
              fontSize: 16,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            Constant.amountShow(
              amount: cartProductModel.discountPrice.toString(),
            ),
            style: TextStyle(
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey400,
              color: AppThemeData.grey400,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (double.parse(cartProductModel.discountPrice ?? "0.0") <= 0) {
      return Text(
        Constant.amountShow(amount: cartProductModel.price),
        style: TextStyle(
          fontSize: 16,
          color: AppThemeData.grey900,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Row(
        children: [
          Text(
            Constant.amountShow(
              amount: cartProductModel.discountPrice.toString(),
            ),
            style: TextStyle(
              fontSize: 16,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            Constant.amountShow(amount: cartProductModel.price),
            style: TextStyle(
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey400,
              color: AppThemeData.grey400,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRateButton(
    BuildContext context,
    CartProductModel cartProductModel,
  ) {
    return Consumer<RateProductProvider>(
      builder: (context, rateProductProvider, _) {
        return Align(
          alignment: Alignment.centerRight,
          child: RoundedButtonFill(
            title: "Rate us".tr,
            height: 3.8,
            width: 20,
            color: AppThemeData.warning300,
            textColor: AppThemeData.grey800,
            onPress: () async {
              final orderDetailsProvider = Provider.of<OrderDetailsProvider>(
                context,
                listen: false,
              );
              rateProductProvider.initFunction(
                orderModel: orderDetailsProvider.orderModel,
                productId: cartProductModel.id.toString(),
              );
              Get.to(const RateProductScreen());
            },
          ),
        );
      },
    );
  }

  Widget _buildVariants(CartProductModel cartProductModel) {
    final variantInfo = cartProductModel.variantInfo;
    if (variantInfo == null || variantInfo.variantOptions == null) {
      return const SizedBox();
    }

    final opts = variantInfo.variantOptions;
    final List<Widget> chips = [];

    if (opts is Map) {
      opts.forEach((key, value) {
        // Do not show merchant_price in UI (used only for order payload)
        if (key == 'merchant_price') return;
        chips.add(
          Container(
            decoration: ShapeDecoration(
              color: AppThemeData.grey100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                "$key : $value",
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey400,
                ),
              ),
            ),
          ),
        );
      });
    } else if (opts is List) {
      for (final value in opts) {
        chips.add(
          Container(
            decoration: ShapeDecoration(
              color: AppThemeData.grey100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey400,
                ),
              ),
            ),
          ),
        );
      }
    } else {
      chips.add(
        Container(
          decoration: ShapeDecoration(
            color: AppThemeData.grey100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Text(
              opts.toString(),
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey400,
              ),
            ),
          ),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Variants".tr,
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(spacing: 6.0, runSpacing: 6.0, children: chips),
        ],
      ),
    );
  }

  Widget _buildExtras(CartProductModel cartProductModel) {
    if (cartProductModel.extras == null || cartProductModel.extras!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Addons".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              Constant.amountShow(
                amount:
                    (double.parse(cartProductModel.extrasPrice.toString()) *
                            double.parse(cartProductModel.quantity.toString()))
                        .toString(),
              ),
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.primary300,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: cartProductModel.extras!.map((extra) {
            return Container(
              decoration: ShapeDecoration(
                color: AppThemeData.grey100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Text(
                  extra.toString(),
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeliveryFeeWidget({
    required OrderModel order,
    required OrderBillDetails bill,
    required bool hasPromotionalItems,
    required double totalDistance,
    required VendorModel vendor,
  }) {
    final deliveryChargeModel = vendor.deliveryCharge;
    final double baseCharge = _getDoubleValue(
      deliveryChargeModel?.baseDeliveryCharge,
      _fallbackBaseCharge,
    );
    final double threshold = _getDoubleValue(
      deliveryChargeModel?.itemTotalThreshold,
      _fallbackThreshold,
    );
    final double freeKm = _getDoubleValue(
      deliveryChargeModel?.freeDeliveryDistanceKm,
      _fallbackFreeKm,
    );
    final double payableDeliveryFee = bill.deliveryCharges < 0
        ? 0.0
        : bill.deliveryCharges;

    if (vendor.isSelfDelivery == true &&
        Constant.isSelfDeliveryFeature == true) {
      return Text(
        'Free Delivery',
        style: TextStyle(
          fontFamily: AppThemeData.regular,
          color: AppThemeData.success400,
          fontSize: 16,
        ),
      );
    }

    if (hasPromotionalItems) {
      final bool isWithinPromoFreeRadius =
          totalDistance <= _promoFreeDeliveryKm;
      final double promoCurrentFee = isWithinPromoFreeRadius
          ? 0.0
          : payableDeliveryFee;

      return buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseCharge,
        currentFee: promoCurrentFee,
      );
    }

    final bool qualifiesForFreeByThreshold = bill.subTotal >= threshold;
    if (qualifiesForFreeByThreshold) {
      final bool isWithinFreeDistance = totalDistance <= freeKm;
      final double currentFee = isWithinFreeDistance ? 0.0 : payableDeliveryFee;

      return buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseCharge,
        currentFee: currentFee,
      );
    }

    return buildDeliveryFeeUI(
      isFreeDelivery: false,
      originalFee: 0.0,
      currentFee: payableDeliveryFee,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsProvider>(
      builder: (context, controller, _) {
        final order = controller.orderModel;

        if (order.products == null || order.products!.isEmpty) {
          return _buildErrorScreen(
            "Order details are incomplete. Please contact support.".tr,
          );
        }

        final vendor = order.vendor ?? _createDefaultMartVendor();
        final deliveryCharge = vendor.deliveryCharge ?? DeliveryCharge();
        final totalDistance = order.vendor != null
            ? Constant.calculateDistance(
                vendor.latitude ?? 0.0,
                vendor.longitude ?? 0.0,
                order.address?.location?.latitude ?? 0.0,
                order.address?.location?.longitude ?? 0.0,
              )
            : 0.0;

        return FutureBuilder<OrderBillDetails>(
          future: _calculateOrderBillDetails(
            order,
            vendor,
            deliveryCharge,
            totalDistance,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (snapshot.hasError) {
              return _buildErrorScreen("Error loading order details".tr);
            }

            final bill = snapshot.data!;
            final hasPromotionalItems =
                _calculateSubTotal(order)['hasPromotionalItems'] as bool;

            return Scaffold(
              backgroundColor: AppThemeData.surface,
              appBar: AppBar(
                backgroundColor: AppThemeData.surface,
                centerTitle: false,
                titleSpacing: 0,
                title: Text(
                  "Order Details".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 16,
                    color: AppThemeData.grey900,
                  ),
                ),
              ),
              body: controller.isLoading
                  ? Constant.loader(message: "Loading order details...".tr)
                  : _buildContent(
                      context,
                      controller,
                      order,
                      vendor,
                      bill,
                      hasPromotionalItems,
                      totalDistance,
                    ),
              bottomNavigationBar: _buildBottomNavigationBar(
                context,
                controller,
                order,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Order Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
      ),
      body: Constant.loader(message: "Loading order details...".tr),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Order Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
      ),
      body: Center(child: Text(message.tr)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
    VendorModel vendor,
    OrderBillDetails bill,
    bool hasPromotionalItems,
    double totalDistance,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            _buildOrderHeader(controller, order),
            const SizedBox(height: 14),

            // Vendor/Address section
            order.takeAway == true
                ? _buildTakeAwaySection(context, controller, order)
                : _buildDeliverySection(context, controller, order),
            const SizedBox(height: 14),

            // Your Order section
            _buildYourOrderSection(context, controller),
            const SizedBox(height: 14),

            // Bill Details section
            _buildBillDetailsSection(
              order,
              bill,
              hasPromotionalItems,
              totalDistance,
              vendor,
            ),
            const SizedBox(height: 14),

            // Order Details section
            _buildOrderDetailsSection(order),

            // Remarks section (conditional)
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildRemarksSection(order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderDetailsProvider controller, OrderModel order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${'Order'.tr} ${Constant.orderId(orderId: order.id.toString())}"
                    .tr,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 18,
                  color: AppThemeData.grey900,
                ),
              ),
            ],
          ),
        ),
        RoundedButtonFill(
          title: order.status.toString().tr,
          color: Constant.statusColor(status: order.status.toString()),
          width: 32,
          height: 4.5,
          radius: 10,
          textColor: Constant.statusText(status: order.status.toString()),
          onPress: () {},
        ),
      ],
    );
  }

  Widget _buildTakeAwaySection(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    return Container(
      decoration: ShapeDecoration(
        color: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.vendor?.title ?? 'Jippy Mart',
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 16,
                      color: AppThemeData.primary300,
                    ),
                  ),
                  Text(
                    order.vendor?.location ?? 'Jippy Mart Store',
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
                      color: AppThemeData.grey600,
                    ),
                  ),
                ],
              ),
            ),
            _buildContactButtons(context, controller, order, isTakeAway: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    return Container(
      decoration: ShapeDecoration(
        color: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Timeline.tileBuilder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              theme: TimelineThemeData(nodePosition: 0),
              builder: TimelineTileBuilder.connected(
                contentsAlign: ContentsAlign.basic,
                indicatorBuilder: (context, index) {
                  return SvgPicture.asset("assets/icons/ic_location.svg");
                },
                connectorBuilder: (context, index, connectorType) {
                  return const DashedLineConnector(
                    color: AppThemeData.grey300,
                    gap: 3,
                  );
                },
                contentsBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: index == 0
                        ? _buildVendorInfo(context, controller, order)
                        : _buildDeliveryAddress(order),
                  );
                },
                itemCount: 2,
              ),
            ),
            if (order.status != Constant.orderRejected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: MySeparator(color: AppThemeData.grey200),
              ),
              _buildDriverInfo(context, controller, order),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfo(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.vendor?.title ?? 'Jippy Mart',
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 16,
                  color: AppThemeData.primary300,
                ),
              ),
              Text(
                order.vendor?.location ?? 'Jippy Mart Store',
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 14,
                  color: AppThemeData.grey600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildChatButton(context, controller, order, isVendor: true),
      ],
    );
  }

  Widget _buildDeliveryAddress(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${order.address!.addressAs}",
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.primary300,
          ),
        ),
        Text(
          order.address!.getFullAddress(),
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 14,
            color: AppThemeData.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    if (order.status == Constant.orderCompleted && order.driver != null) {
      return Row(
        children: [
          SvgPicture.asset("assets/icons/ic_check_small.svg"),
          const SizedBox(width: 5),
          Text(
            order.driver!.fullName(),
            style: TextStyle(
              color: AppThemeData.grey800,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            "Order Delivered.".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontFamily: AppThemeData.regular,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else if (order.status == Constant.orderAccepted ||
        order.status == Constant.driverPending) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset("assets/icons/ic_timer.svg"),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              "${'Your Order has been Preparing and assign to the driver'.tr}\n${'Preparation Time'.tr} ${order.estimatedTimeToPrepare}"
                  .tr,
              style: TextStyle(
                color: AppThemeData.warning400,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    } else if (order.driver != null) {
      return Row(
        children: [
          ClipOval(
            child: NetworkImageWidget(
              imageUrl: order.driver!.profilePictureURL.toString(),
              fit: BoxFit.cover,
              height: Responsive.height(5, context),
              width: Responsive.width(10, context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driver!.fullName().toString(),
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  order.driver!.email.toString(),
                  style: TextStyle(
                    color: AppThemeData.success400,
                    fontFamily: AppThemeData.regular,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildContactButtons(context, controller, order, isDriver: true),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildContactButtons(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order, {
    bool isTakeAway = false,
    bool isDriver = false,
  }) {
    final phone = isDriver
        ? order.driver?.phoneNumber?.toString()
        : order.vendor?.phonenumber?.toString();

    return Row(
      children: [
        if (phone != null && phone != 'Contact Support') ...[
          InkWell(
            onTap: () => Constant.makePhoneCall(phone),
            child: Container(
              width: 42,
              height: 42,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: AppThemeData.grey200),
                  borderRadius: BorderRadius.circular(120),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset("assets/icons/ic_phone_call.svg"),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        InkWell(
          onTap: () => _onChatButtonPressed(
            context,
            controller,
            order,
            isDriver: isDriver,
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: AppThemeData.grey200),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order, {
    bool isVendor = false,
  }) {
    return InkWell(
      onTap: () =>
          _onChatButtonPressed(context, controller, order, isVendor: isVendor),
      child: Container(
        width: 42,
        height: 42,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: AppThemeData.grey200),
            borderRadius: BorderRadius.circular(120),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
        ),
      ),
    );
  }

  Future<void> _onChatButtonPressed(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order, {
    bool isVendor = false,
    bool isDriver = false,
  }) async {
    ShowToastDialog.showLoader("Please wait".tr);

    try {
      UserModel? customer = await AddressListProvider.getUserProfile(
        order.authorID.toString(),
      );

      UserModel? otherUser;
      if (isDriver) {
        otherUser = await AddressListProvider.getUserProfile(
          order.driverID.toString(),
        );
      } else if (isVendor) {
        otherUser = await AddressListProvider.getUserProfile(
          order.vendor!.author.toString(),
        );
      }

      ShowToastDialog.closeLoader();

      if (customer != null && otherUser != null) {
        final userId = await SqlStorageConst.getFirebaseId();
        Get.to(
          ChatScreen(userId: userId),
          arguments: {
            "customerName": customer.fullName(),
            "restaurantName": otherUser.fullName(),
            "orderId": order.id,
            "restaurantId": otherUser.id,
            "customerId": customer.id,
            "customerProfileImage": customer.profilePictureURL,
            "restaurantProfileImage": otherUser.profilePictureURL,
            "token": otherUser.fcmToken,
            "chatType": isDriver ? "Driver" : "restaurant",
          },
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
    }
  }

  Widget _buildYourOrderSection(
    BuildContext context,
    OrderDetailsProvider controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Order".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.orderModel.products!.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildProductItem(
                  context,
                  controller.orderModel.products![index],
                );
              },
              separatorBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: MySeparator(color: AppThemeData.grey200),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillDetailsSection(
    OrderModel order,
    OrderBillDetails bill,
    bool hasPromotionalItems,
    double totalDistance,
    VendorModel vendor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bill Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                _buildBillRow(
                  label: "Item totals".tr,
                  value: Constant.amountShow(amount: bill.subTotal.toString()),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Delivery Fee".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildDeliveryFeeWidget(
                      order: order,
                      bill: bill,
                      hasPromotionalItems: hasPromotionalItems,
                      totalDistance: totalDistance,
                      vendor: vendor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Platform Fee".tr,
                  value: '15.00',
                  isStrikethrough: true,
                  color: AppThemeData.danger300,
                ),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Surge Fee".tr,
                  value: "₹${surgeFee ?? 0.0}",
                ),
                const SizedBox(height: 10),
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Coupon Discount".tr,
                  value:
                      "- (${Constant.amountShow(amount: order.discount.toString())})",
                  color: AppThemeData.danger300,
                ),
                if (order.specialDiscount != null &&
                    order.specialDiscount!['special_discount'] != null) ...[
                  const SizedBox(height: 10),
                  _buildBillRow(
                    label: "Special Discount".tr,
                    value:
                        "- (${Constant.amountShow(amount: order.specialDiscount!['special_discount'].toString())})",
                    color: AppThemeData.danger300,
                  ),
                ],
                if (order.takeAway != true &&
                    vendor.isSelfDelivery != true) ...[
                  const SizedBox(height: 10),
                  _buildBillRow(
                    label: "Delivery Tips".tr,
                    value: Constant.amountShow(
                      amount: order.tipAmount.toString(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "Taxes & Charges",
                  value: Constant.amountShow(amount: bill.taxAmount.toString()),
                ),
                const SizedBox(height: 10),
                _buildBillRow(
                  label: "To Pay".tr,
                  value: Constant.amountShow(
                    amount: "${bill.totalAmount + (surgeFee ?? 0.0)}",
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow({
    required String label,
    required String value,
    Color? color,
    bool isStrikethrough = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            color: color ?? AppThemeData.grey900,
            fontSize: 16,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: color ?? AppThemeData.danger300,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Order Details".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                _buildOrderDetailRow(
                  label: "Delivery type".tr,
                  value: order.takeAway == true
                      ? "TakeAway".tr
                      : order.scheduleTime == null
                      ? "Standard".tr
                      : "Schedule".tr,
                  valueColor: order.scheduleTime != null
                      ? AppThemeData.primary300
                      : AppThemeData.grey900,
                ),
                const SizedBox(height: 10),
                _buildOrderDetailRow(
                  label: "Payment Method".tr,
                  value: order.paymentMethod.toString(),
                ),
                const SizedBox(height: 10),
                _buildOrderDetailRow(
                  label: "Date and Time".tr,
                  value: Constant.timestampToDateTime(order.createdAt!),
                  valueColor: AppThemeData.grey600,
                ),
                const SizedBox(height: 10),
                _buildOrderDetailRow(
                  label: "Phone Number".tr,
                  value: order.author!.phoneNumber.toString(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailRow({
    required String label,
    required String value,
    Color valueColor = AppThemeData.grey900,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            color: valueColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Remarks".tr,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Text(
              order.notes.toString(),
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    OrderDetailsProvider controller,
    OrderModel order,
  ) {
    if (order.status == Constant.orderShipped ||
        order.status == Constant.orderInTransit ||
        order.status == Constant.orderCompleted) {
      return Container(
        color: AppThemeData.grey50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child:
              order.status == Constant.orderShipped ||
                  order.status == Constant.orderInTransit
              ? Consumer<LiveTrackingProvider>(
                  builder: (context, liveTrackingProvider, _) {
                    return RoundedButtonFill(
                      title: "Track Order".tr,
                      height: 5.5,
                      color: AppThemeData.warning300,
                      textColor: AppThemeData.grey900,
                      onPress: () {
                        liveTrackingProvider.initFunction(orderModel: order);
                        Get.to(const LiveTrackingScreen());
                      },
                    );
                  },
                )
              : RoundedButtonFill(
                  title: "Reorder".tr,
                  height: 5.5,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    final orderProvider = Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    );
                    await orderProvider.reorderOrder(order, context);
                  },
                ),
        ),
      );
    }
    return const SizedBox();
  }

  VendorModel _createDefaultMartVendor() {
    final cachedDeliveryCharge = _cachedMartDeliveryCharge;
    final deliveryCharge =
        (cachedDeliveryCharge != null && _isDeliveryChargeCacheValid())
        ? cachedDeliveryCharge
        : null;

    return VendorModel(
      title: "Jippy Mart",
      location: "Jippy Mart Store",
      phonenumber: "Contact Support",
      isSelfDelivery: false,
      deliveryCharge: deliveryCharge,
      latitude: 0.0,
      longitude: 0.0,
      vType: 'mart',
    );
  }
}
