import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/cart_screen/widget/cart_build_delivery_ui.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/currency_display.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Bill Details Card – Zomato-inspired
/// All calculation logic is preserved exactly.
/// ─────────────────────────────────────────────────────────────────────────────
Widget billCartWidget(CartControllerProvider controller, BuildContext context) {
  final hasPromotionalItems = controller.hasPromotionalItems();
  final hasMartItems = controller.hasMartItemsInCart();

  final hasSavings =
      controller.couponAmount > 0 || controller.specialDiscountAmount > 0;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: AppThemeData.grey600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey900,
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: AppThemeData.grey100),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            children: [
              // Item total
              _billRow(
                label: 'Item total',
                value: Constant.amountShow(
                  amount: controller.subTotal.toString(),
                ),
                controller: controller,
              ),

              const SizedBox(height: 10),

              // Delivery fee
              if (controller.selectedFoodType != 'TakeAway') ...[
                _buildDeliveryFeeRow(
                  controller,
                  hasPromotionalItems,
                  hasMartItems,
                ),
                const SizedBox(height: 10),
              ],

              // Platform fee – Free
              _billRow(
                label: 'Platform fee',
                value: 'Free',
                strikeValue: '₹15',
                valueColor: AppThemeData.success400,
                controller: controller,
              ),

              const SizedBox(height: 10),

              // Surge fee
              _buildSurgeFeeRow(controller),

              const SizedBox(height: 10),

              // ── Savings section ──────────────────────────────────────────
              if (hasSavings) ...[
                _buildDashedDivider(),
                const SizedBox(height: 10),
              ],

              // Coupon discount
              _buildCouponRow(controller),

              // Special discount
              if (controller.specialDiscountAmount > 0) ...[
                const SizedBox(height: 10),
                _billRow(
                  label: 'Special Discount',
                  value:
                      '- ${Constant.amountShow(amount: controller.specialDiscountAmount.toString())}',
                  valueColor: AppThemeData.danger300,
                  controller: controller,
                ),
              ],

              // Delivery tips
              if (controller.selectedFoodType != 'TakeAway' &&
                  !(controller.vendorModel.isSelfDelivery == true &&
                      Constant.isSelfDeliveryFeature == true)) ...[
                const SizedBox(height: 10),
                _buildDeliveryTipsRow(controller),
              ],

              const SizedBox(height: 10),

              // ── Taxes ────────────────────────────────────────────────────
              _buildDashedDivider(),
              const SizedBox(height: 10),

              _billRow(
                label: 'Taxes & charges',
                value: Constant.amountShow(
                  amount: controller.taxAmount.toString(),
                ),
                controller: controller,
              ),

              const SizedBox(height: 12),

              // ── Total ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppThemeData.primary50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppThemeData.primary300.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'To Pay',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.semiBold,
                          color: AppThemeData.grey900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary300.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payableAmountDisplay(controller.totalAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: AppThemeData.bold,
                          fontWeight: FontWeight.w800,
                          color: AppThemeData.primary300,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Wallet deduction breakdown
              if (controller.useWalletBalance &&
                  controller.walletToUse > 0) ...[
                const SizedBox(height: 8),
                _walletDeductionRows(controller),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── ROW HELPERS ──────────────────────────────────────────────────────────────

Widget _billRow({
  required String label,
  required String value,
  String? strikeValue,
  Color? valueColor,
  Widget? labelSuffix,
  required CartControllerProvider controller,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey600,
              ),
            ),
            if (labelSuffix != null) ...[const SizedBox(width: 6), labelSuffix],
          ],
        ),
      ),
      if (strikeValue != null) ...[
        Text(
          strikeValue,
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppThemeData.regular,
            color: AppThemeData.grey400,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 6),
      ],
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontFamily: AppThemeData.medium,
          color: valueColor ?? AppThemeData.grey900,
        ),
      ),
    ],
  );
}

Widget _buildDashedDivider() {
  return Row(
    children: List.generate(
      60,
      (i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          height: 1,
          color: i.isEven ? AppThemeData.grey200 : Colors.transparent,
        ),
      ),
    ),
  );
}

Widget _buildDeliveryFeeRow(
  CartControllerProvider controller,
  bool hasPromotionalItems,
  bool hasMartItems,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          'Delivery fee',
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.regular,
            color: AppThemeData.grey600,
          ),
        ),
      ),
      _buildDeliveryFeeSection(controller, hasPromotionalItems, hasMartItems),
    ],
  );
}

Widget _buildSurgeFeeRow(CartControllerProvider controller) {
  final isFree = controller.surgePercent <= 0;
  return Row(
    children: [
      Expanded(
        child: Text(
          'Surge fee',
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.regular,
            color: AppThemeData.grey600,
          ),
        ),
      ),
      if (isFree) ...[
        Text(
          'Free',
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.medium,
            color: AppThemeData.success400,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '₹10',
          style: TextStyle(
            fontSize: 12,
            color: AppThemeData.grey400,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ] else
        Text(
          '₹${controller.surgePercent}',
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.medium,
            color: AppThemeData.grey900,
          ),
        ),
    ],
  );
}

Widget _buildCouponRow(CartControllerProvider controller) {
  final hasCoupon =
      controller.selectedCouponModel.id != null &&
      controller.selectedCouponModel.id!.isNotEmpty;
  final couponDisabled = controller.isCouponDisabledByWallet;

  return Opacity(
    opacity: couponDisabled ? 0.5 : 1,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coupon discount',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.regular,
                  color: AppThemeData.grey600,
                ),
              ),
              if (couponDisabled)
                Text(
                  'Not applicable with wallet',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppThemeData.grey400,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              controller.couponAmount > 0
                  ? '- ${Constant.amountShow(amount: controller.couponAmount.toString())}'
                  : '—',
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.medium,
                color: controller.couponAmount > 0
                    ? AppThemeData.danger300
                    : AppThemeData.grey400,
              ),
            ),
            if (hasCoupon && !couponDisabled) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  controller.selectedCouponModel = CouponModel();
                  controller.couponCodeController.text = '';
                  controller.couponAmount = 0.0;
                  controller.calculatePrice();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.danger300,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

Widget _buildDeliveryTipsRow(CartControllerProvider controller) {
  return Row(
    children: [
      Expanded(
        child: Row(
          children: [
            Text(
              'Delivery tip',
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey600,
              ),
            ),
            if (controller.deliveryTips > 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  controller.deliveryTips = 0;
                  controller.calculatePrice();
                },
                child: Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.primary300,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      Text(
        controller.deliveryTips > 0
            ? Constant.amountShow(amount: controller.deliveryTips.toString())
            : '—',
        style: TextStyle(
          fontSize: 13,
          fontFamily: AppThemeData.medium,
          color: controller.deliveryTips > 0
              ? AppThemeData.grey900
              : AppThemeData.grey400,
        ),
      ),
    ],
  );
}

Widget _walletDeductionRows(CartControllerProvider controller) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppThemeData.primary50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppThemeData.primary200),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: AppThemeData.primary300,
                ),
                const SizedBox(width: 4),
                Text(
                  'Wallet deduction',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.regular,
                    color: AppThemeData.grey600,
                  ),
                ),
              ],
            ),
            Text(
              '-${Constant.amountShow(amount: controller.walletToUse.toStringAsFixed(2))}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.medium,
                color: AppThemeData.danger300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pay via payment gateway',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
              ),
            ),
            Text(
              Constant.amountShow(
                amount: controller.paymentGatewayAmount.toStringAsFixed(2),
              ),
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.primary300,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── DELIVERY FEE SECTION (all calc logic unchanged) ─────────────────────────

Widget _buildDeliveryFeeSection(
  CartControllerProvider controller,
  bool hasPromotionalItems,
  bool hasMartItems,
) {
  if (controller.vendorModel.isSelfDelivery == true &&
      Constant.isSelfDeliveryFeature == true) {
    return Text(
      'Free',
      style: TextStyle(
        fontSize: 13,
        fontFamily: AppThemeData.medium,
        color: AppThemeData.success400,
      ),
    );
  }

  if (hasPromotionalItems) {
    final baseCharge =
        controller.deliveryChargeModel.baseDeliveryCharge?.toDouble() ?? 21.0;
    return buildDeliveryFeeUI(
      isFreeDelivery: true,
      originalFee: baseCharge,
      currentFee: controller.deliveryCharges,
    );
  }

  if (hasMartItems) {
    final dc = controller.deliveryChargeModel;
    final itemThreshold = dc.itemTotalThreshold?.toDouble() ?? 199.0;
    final freeDeliveryKm = dc.freeDeliveryDistanceKm?.toDouble() ?? 3.0;
    final baseDeliveryCharge = dc.baseDeliveryCharge?.toDouble() ?? 21.0;
    final subtotal = controller.subTotal;
    final distance = controller.totalDistance;
    final isAboveThreshold = subtotal >= itemThreshold;
    final isWithinFreeDistance = distance <= freeDeliveryKm;

    if (isAboveThreshold) {
      if (isWithinFreeDistance) {
        return buildDeliveryFeeUI(
          isFreeDelivery: true,
          originalFee: baseDeliveryCharge,
          currentFee: 0.0,
        );
      } else {
        return buildDeliveryFeeUI(
          isFreeDelivery: true,
          originalFee: baseDeliveryCharge,
          currentFee: controller.deliveryCharges,
        );
      }
    } else {
      return buildDeliveryFeeUI(
        isFreeDelivery: false,
        originalFee: 0.0,
        currentFee: controller.deliveryCharges,
      );
    }
  }

  // Regular items
  final dc = controller.deliveryChargeModel;
  final threshold = dc.itemTotalThreshold?.toDouble() ?? 299.0;
  final freeKm = dc.freeDeliveryDistanceKm?.toDouble() ?? 7.0;
  final subtotal = controller.subTotal;
  final distance = controller.totalDistance;
  final isAboveThreshold = subtotal >= threshold;
  final isWithinFreeDistance = distance <= freeKm;
  final baseDeliveryCharge = dc.baseDeliveryCharge?.toDouble() ?? 21.0;

  if (isAboveThreshold) {
    if (isWithinFreeDistance) {
      return buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseDeliveryCharge,
        currentFee: 0.0,
      );
    } else {
      return buildDeliveryFeeUI(
        isFreeDelivery: true,
        originalFee: baseDeliveryCharge,
        currentFee: controller.deliveryCharges,
      );
    }
  } else {
    return buildDeliveryFeeUI(
      isFreeDelivery: false,
      originalFee: 0.0,
      currentFee: controller.deliveryCharges,
    );
  }
}
