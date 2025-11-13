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

Widget billCartWidget(CartControllerProvider controller, BuildContext context) {
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
                controller.selectedFoodType == 'TakeAway'
                    ? const SizedBox()
                    : Row(
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
                          // Check if cart has promotional items or mart items
                          Obx(() {
                            final hasPromotionalItems = controller
                                .hasPromotionalItems();
                            final hasMartItems = controller
                                .hasMartItemsInCart();

                            // Self delivery check
                            if (controller.vendorModel.isSelfDelivery == true &&
                                Constant.isSelfDeliveryFeature == true) {
                              return Text(
                                'Free Delivery',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  color: AppThemeData.success400,
                                  fontSize: 16,
                                ),
                              );
                            }

                            // Promotional items delivery logic
                            if (hasPromotionalItems) {
                              // For promotional items, always show "Free Delivery" UI with strikethrough ₹23
                              // because promotional items are eligible for free delivery base
                              return buildDeliveryFeeUI(
                                isFreeDelivery: true,
                                originalFee: 23.0,
                                currentFee: controller.deliveryCharges,
                              );
                            }

                            if (hasMartItems) {
                              print(
                                '[CART_UI] 🛒 Building mart delivery UI...',
                              );

                              // For mart items, use the same logic as restaurant items
                              // Get mart delivery settings (static values like restaurant)
                              double itemThreshold =
                                  199.0; // Default mart threshold
                              double freeDeliveryKm =
                                  5.0; // Default mart free distance
                              double baseDeliveryCharge =
                                  23.0; // Static base charge

                              final subtotal = controller.subTotal;
                              final distance = controller.totalDistance;

                              print(
                                '[CART_UI]   - Mart threshold: ₹$itemThreshold',
                              );
                              print(
                                '[CART_UI]   - Mart free distance: ${freeDeliveryKm} km',
                              );
                              print(
                                '[CART_UI]   - Base delivery charge: ₹$baseDeliveryCharge',
                              );

                              // Determine delivery eligibility and charges (same logic as restaurant)
                              final isAboveThreshold =
                                  subtotal >= itemThreshold;
                              final isWithinFreeDistance =
                                  distance <= freeDeliveryKm;

                              print(
                                '[CART_UI]   - Is above threshold: $isAboveThreshold',
                              );
                              print(
                                '[CART_UI]   - Is within free distance: $isWithinFreeDistance',
                              );

                              if (isAboveThreshold) {
                                // Above threshold - eligible for free delivery logic
                                if (isWithinFreeDistance) {
                                  // Standard free delivery: Green "Free Delivery" + strikethrough base charge + ₹0.00
                                  print(
                                    '[CART_UI]   - Mart standard free delivery',
                                  );
                                  return buildDeliveryFeeUI(
                                    isFreeDelivery: true,
                                    originalFee: baseDeliveryCharge,
                                    currentFee: 0.0,
                                  );
                                } else {
                                  // Free delivery with extra charge: Green "Free Delivery" + strikethrough base charge + extra charge
                                  print(
                                    '[CART_UI]   - Mart free delivery with extra charge',
                                  );
                                  return buildDeliveryFeeUI(
                                    isFreeDelivery: true,
                                    originalFee: baseDeliveryCharge,
                                    currentFee: controller.deliveryCharges,
                                  );
                                }
                              } else {
                                // Below threshold - regular paid delivery
                                print(
                                  '[CART_UI]   - Mart regular paid delivery',
                                );
                                return buildDeliveryFeeUI(
                                  isFreeDelivery: false,
                                  originalFee: 0.0,
                                  currentFee: controller.deliveryCharges,
                                );
                              }
                            }

                            // Regular items delivery logic
                            final threshold =
                                controller
                                    .deliveryChargeModel
                                    .itemTotalThreshold ??
                                299;
                            final freeKm =
                                controller
                                    .deliveryChargeModel
                                    .freeDeliveryDistanceKm ??
                                7;
                            final subtotal = controller.subTotal;
                            final distance = controller.totalDistance;

                            final isAboveThreshold = subtotal >= threshold;
                            final isWithinFreeDistance = distance <= freeKm;

                            // Get the base delivery charge for restaurant items (should be ₹23)
                            double baseDeliveryCharge =
                                (controller
                                            .deliveryChargeModel
                                            .baseDeliveryCharge ??
                                        23.0)
                                    .toDouble();
                            print(
                              '[CART_UI]   - Base delivery charge: ₹$baseDeliveryCharge',
                            );

                            if (isAboveThreshold) {
                              if (isWithinFreeDistance) {
                                print('[CART_UI]   - Standard free delivery');
                                return buildDeliveryFeeUI(
                                  isFreeDelivery: true,
                                  originalFee: baseDeliveryCharge,
                                  currentFee: 0.0,
                                );
                              } else {
                                // Free delivery with extra charge: Green "Free Delivery" + strikethrough base charge + extra charge
                                print(
                                  '[CART_UI]   - Free delivery with extra charge',
                                );
                                return buildDeliveryFeeUI(
                                  isFreeDelivery: true,
                                  originalFee: baseDeliveryCharge,
                                  // Show base charge, not calculated total
                                  currentFee: controller.deliveryCharges,
                                );
                              }
                            } else {
                              // Below threshold - regular paid delivery
                              print('[CART_UI]   - Regular paid delivery');
                              return buildDeliveryFeeUI(
                                isFreeDelivery: false,
                                originalFee: 0.0,
                                currentFee: controller.deliveryCharges,
                              );
                            }
                          }),
                        ],
                      ),
                const SizedBox(height: 10),
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
                        SizedBox(width: 10),
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
                        controller.selectedCouponModel.id != null &&
                                controller.selectedCouponModel.id!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    controller.selectedCouponModel =
                                        CouponModel();
                                    controller.couponCodeController.text = '';
                                    controller.couponAmount = 0.0;
                                    controller.calculatePrice();
                                  },
                                  child: Text(
                                    "Remove",
                                    style: TextStyle(
                                      color: AppThemeData.danger300,
                                      fontFamily: AppThemeData.medium,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
                controller.specialDiscountAmount > 0
                    ? Column(
                        children: [
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
                      )
                    : const SizedBox(),
                const SizedBox(height: 10),
                controller.selectedFoodType == 'TakeAway' ||
                        (controller.vendorModel.isSelfDelivery == true &&
                            Constant.isSelfDeliveryFeature == true)
                    ? const SizedBox()
                    : Row(
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
                                controller.deliveryTips == 0
                                    ? const SizedBox()
                                    : InkWell(
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
                MySeparator(color: AppThemeData.grey200),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Taxes & Charges",
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
