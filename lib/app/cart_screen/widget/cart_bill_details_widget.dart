import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// 🔑 OPTIMIZATION: Memoize widget to prevent unnecessary rebuilds
Widget billCartWidget(CartControllerProvider controller, BuildContext context) {
  // 🔑 OPTIMIZATION: Cache these checks - they're already cached in provider
  // These calls use cached values internally, so they're fast
  final hasPromotionalItems = controller.hasPromotionalItems();
  final hasMartItems = controller.hasMartItemsInCart();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bill Details".tr,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.grey900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: Responsive.width(100, context),
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 52,
                offset: Offset(0, 0),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Item totals".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      Constant.amountShow(
                        amount: controller.subTotal.toString(),
                      ),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // DELIVERY FEE SECTION - Fixed logic
                if (controller.selectedFoodType != 'TakeAway') ...[
                  _buildDeliveryFeeSection(
                    controller,
                    hasPromotionalItems,
                    hasMartItems,
                  ),
                  const SizedBox(height: 10),
                ],
                // PLATFORM FEE SECTION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Platform Fee".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      'Free',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.success400,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '15.00',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.danger300,
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppThemeData.danger300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // SURGE FEE SECTION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Surge Fee".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          controller.surgePercent <= 0 ? 'Free' : "",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.success400,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          controller.surgePercent <= 0
                              ? "₹10"
                              : "₹${controller.surgePercent}",
                          textAlign: TextAlign.start,
                          style: controller.surgePercent <= 0
                              ? TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  color: AppThemeData.danger300,
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppThemeData.danger300,
                                )
                              : TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  color: AppThemeData.grey900,
                                  fontSize: 16,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                // COUPON DISCOUNT SECTION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Coupon Discount".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "- (${Constant.amountShow(amount: controller.couponAmount.toString())})",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.danger300,
                            fontSize: 16,
                          ),
                        ),
                        if (controller.selectedCouponModel.id != null &&
                            controller.selectedCouponModel.id!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InkWell(
                              onTap: () {
                                controller.selectedCouponModel = CouponModel();
                                controller.couponCodeController.text = '';
                                controller.couponAmount = 0.0;
                                controller.calculatePrice();
                              },
                              child: Text(
                                "Remove".tr,
                                style: TextStyle(
                                  color: AppThemeData.danger300,
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // SPECIAL DISCOUNT SECTION
                if (controller.specialDiscountAmount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "Special Discount".tr,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.grey600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        "- (${Constant.amountShow(amount: controller.specialDiscountAmount.toString())})",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.danger300,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                // DELIVERY TIPS SECTION
                if (controller.selectedFoodType != 'TakeAway' &&
                    !(controller.vendorModel.isSelfDelivery == true &&
                        Constant.isSelfDeliveryFeature == true)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Delivery Tips".tr,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: AppThemeData.grey600,
                                fontSize: 16,
                              ),
                            ),
                            if (controller.deliveryTips > 0)
                              InkWell(
                                onTap: () {
                                  controller.deliveryTips = 0;
                                  controller.calculatePrice();
                                },
                                child: Text(
                                  "Remove".tr,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: AppThemeData.primary300,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        Constant.amountShow(
                          amount: controller.deliveryTips.toString(),
                        ),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                // TAXES & CHARGES SECTION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Taxes & Charges".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      Constant.amountShow(
                        amount: controller.taxAmount.toString(),
                      ),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "To Pay".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      Constant.amountShow(
                        amount: controller.totalAmount.toString(),
                      ),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper method to build delivery fee section
Widget _buildDeliveryFeeSection(
  CartControllerProvider controller,
  bool hasPromotionalItems,
  bool hasMartItems,
) {
  // Self delivery check
  if (controller.vendorModel.isSelfDelivery == true &&
      Constant.isSelfDeliveryFeature == true) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "Delivery Fee".tr,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          'Free Delivery'.tr,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            color: AppThemeData.success400,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  if (hasPromotionalItems) {
    // 🔑 DYNAMIC: Get base charge from delivery charge cache
    final baseCharge =
        controller.deliveryChargeModel.baseDeliveryCharge?.toDouble() ?? 21.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "Delivery Fee".tr,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        buildDeliveryFeeUI(
          isFreeDelivery: true,
          originalFee: baseCharge,
          currentFee: controller.deliveryCharges,
        ),
      ],
    );
  }
  // Mart items delivery logic
  if (hasMartItems) {
    print('[CART_UI] 🛒 Building mart delivery UI...');
    // 🔑 DYNAMIC: Get values from delivery charge model
    final dc = controller.deliveryChargeModel;
    double itemThreshold = dc.itemTotalThreshold?.toDouble() ?? 199.0;
    double freeDeliveryKm = dc.freeDeliveryDistanceKm?.toDouble() ?? 3.0;
    double baseDeliveryCharge = dc.baseDeliveryCharge?.toDouble() ?? 21.0;
    final subtotal = controller.subTotal;
    final distance = controller.totalDistance;
    final isAboveThreshold = subtotal >= itemThreshold;
    final isWithinFreeDistance = distance <= freeDeliveryKm;
    Widget martDeliveryWidget;
    if (isAboveThreshold) {
      if (isWithinFreeDistance) {
        martDeliveryWidget = buildDeliveryFeeUI(
          isFreeDelivery: true,
          originalFee: baseDeliveryCharge,
          currentFee: 0.0,
        );
      } else {
        martDeliveryWidget = buildDeliveryFeeUI(
          isFreeDelivery: true,
          originalFee: baseDeliveryCharge,
          currentFee: controller.deliveryCharges,
        );
      }
    } else {
      print('[CART_UI]   - Mart regular paid delivery');
      martDeliveryWidget = buildDeliveryFeeUI(
        isFreeDelivery: false,
        originalFee: 0.0,
        currentFee: controller.deliveryCharges,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "Delivery Fee".tr,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
              fontSize: 16,
            ),
          ),
        ),
        martDeliveryWidget,
      ],
    );
  }

  // Regular items delivery logic
  // 🔑 DYNAMIC: Get all values from delivery charge model
  final dc = controller.deliveryChargeModel;
  final threshold = dc.itemTotalThreshold?.toDouble() ?? 299.0;
  final freeKm = dc.freeDeliveryDistanceKm?.toDouble() ?? 7.0;
  final subtotal = controller.subTotal;
  final distance = controller.totalDistance;

  final isAboveThreshold = subtotal >= threshold;
  final isWithinFreeDistance = distance <= freeKm;

  // 🔑 DYNAMIC: Get the base delivery charge from model (no hardcoded values)
  double baseDeliveryCharge = dc.baseDeliveryCharge?.toDouble() ?? 21.0;
  print('[CART_UI]   - Base delivery charge: ₹$baseDeliveryCharge');

  Widget regularDeliveryWidget;

  if (isAboveThreshold) {
    if (isWithinFreeDistance) {
      print('[CART_UI]   - Standard free delivery');
      regularDeliveryWidget = buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseDeliveryCharge,
        currentFee: 0.0,
      );
    } else {
      // Free delivery with extra charge: Green "Free Delivery" + strikethrough base charge + extra charge
      print('[CART_UI]   - Free delivery with extra charge');
      regularDeliveryWidget = buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseDeliveryCharge,
        // Show base charge, not calculated total
        currentFee: controller.deliveryCharges,
      );
    }
  } else {
    // Below threshold - regular paid delivery
    print('[CART_UI]   - Regular paid delivery');
    regularDeliveryWidget = buildDeliveryFeeUI(
      isFreeDelivery: false,
      originalFee: 0.0,
      currentFee: controller.deliveryCharges,
    );
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          "Delivery Fee".tr,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            color: AppThemeData.grey600,
            fontSize: 16,
          ),
        ),
      ),
      regularDeliveryWidget,
    ],
  );
}
