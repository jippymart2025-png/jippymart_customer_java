import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SelectPaymentScreen extends StatelessWidget {
  const SelectPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppThemeData.surface,
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              "Payment Option".tr,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: AppThemeData.grey900,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UseWalletSection(controller: controller),
                  const SizedBox(height: 16),
                  if (!controller.isFullyPaidByWallet) ...[
                    Text(
                      "Preferred Payment".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color: AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (controller.cashOnDeliverySettingModel.isEnabled == true)
                      _buildPaymentMethodsCard(
                        controller: controller,
                        child: Column(
                          children: [
                            _codVisibility(controller),
                            _codMaxAmountMessage(controller),
                            _codPromoMessage(controller),
                          ],
                        ),
                      ),
                    if (controller.cashOnDeliverySettingModel.isEnabled == true)
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "Other Payment Options".tr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16,
                              color: AppThemeData.grey900,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    _buildPaymentMethodsCard(
                      controller: controller,
                      child: Visibility(
                        visible: controller.razorPayModel.isEnabled == true,
                        child: cardDecoration(
                          controller,
                          PaymentGateway.razorpay,
                          "assets/images/razorpay.png",
                        ),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppThemeData.primary200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppThemeData.primary300,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Full amount will be paid from wallet".tr,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 14,
                                color: AppThemeData.grey800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, controller),
        );
      },
    );
  }

  String _payButtonTitle(CartControllerProvider controller) {
    if (controller.useWalletBalance &&
        controller.walletToUse > 0 &&
        controller.paymentGatewayAmount > 0) {
      return '${'Pay'.tr} ${Constant.amountShow(amount: controller.walletToUse.toString())} ${'from wallet'.tr} + ${Constant.amountShow(amount: controller.paymentGatewayAmount.toString())} ${'via payment'.tr}';
    }
    if (controller.useWalletBalance && controller.isFullyPaidByWallet) {
      return '${'Pay'.tr} ${Constant.amountShow(amount: controller.totalAmount.toString())} ${'from wallet'.tr}';
    }
    return "${'Pay Now'.tr} | ${Constant.amountShow(amount: controller.totalAmount.toString())}"
        .tr;
  }

  Widget _buildBottomBar(
    BuildContext context,
    CartControllerProvider controller,
  ) {
    final payable = controller.useWalletBalance
        ? controller.paymentGatewayAmount
        : controller.totalAmount;
    return Container(
      decoration: BoxDecoration(
        color: AppThemeData.grey50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.useWalletBalance && controller.walletToUse > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Wallet deduction".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.regular,
                      fontSize: 14,
                      color: AppThemeData.grey600,
                    ),
                  ),
                  Text(
                    "-${Constant.amountShow(amount: controller.walletToUse.toStringAsFixed(2))}",
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
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
                    "Amount to pay".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 15,
                      color: AppThemeData.grey900,
                    ),
                  ),
                  Text(
                    Constant.amountShow(amount: payable.toStringAsFixed(2)),
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 15,
                      color: AppThemeData.grey900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            RoundedButtonFill(
              title: _payButtonTitle(controller),
              height: 5,
              color: AppThemeData.primary300,
              textColor: AppThemeData.grey50,
              fontSizes: 16,
              onPress: () async {
                if (controller.isFullyPaidByWallet) {
                  controller.selectedPaymentMethod = PaymentGateway.wallet.name;
                  await controller.placeOrder(context);
                  if (context.mounted) Get.back();
                } else {
                  Get.back();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPaymentMethodsCard({
    required CartControllerProvider controller,
    required Widget child,
  }) {
    return Container(
      decoration: ShapeDecoration(
        color: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 20,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(8.0), child: child),
    );
  }

  Widget _codVisibility(CartControllerProvider controller) {
    final codAmount = controller.useWalletBalance
        ? controller.amountToChargeViaGateway
        : controller.subTotal;
    final visible =
        controller.cashOnDeliverySettingModel.isEnabled == true &&
        codAmount <= controller.cashOnDeliverySettingModel.getMaxAmount() &&
        !controller.hasPromotionalItems();
    return Visibility(
      visible: visible,
      child: cardDecoration(
        controller,
        PaymentGateway.cod,
        "assets/images/ic_cash.png",
      ),
    );
  }

  Widget _codMaxAmountMessage(CartControllerProvider controller) {
    final codAmount = controller.useWalletBalance
        ? controller.amountToChargeViaGateway
        : controller.subTotal;
    final visible =
        controller.cashOnDeliverySettingModel.isEnabled == true &&
        codAmount > controller.cashOnDeliverySettingModel.getMaxAmount();
    return Visibility(
      visible: visible,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeData.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppThemeData.grey600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Cash on Delivery is not available for orders above ₹${controller.cashOnDeliverySettingModel.getMaxAmount().toStringAsFixed(0)}"
                    .tr,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 14,
                  color: AppThemeData.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codPromoMessage(CartControllerProvider controller) {
    final codAmount = controller.useWalletBalance
        ? controller.amountToChargeViaGateway
        : controller.subTotal;
    final visible =
        controller.cashOnDeliverySettingModel.isEnabled == true &&
        codAmount <= controller.cashOnDeliverySettingModel.getMaxAmount() &&
        controller.hasPromotionalItems();
    return Visibility(
      visible: visible,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeData.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppThemeData.grey600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Cash on Delivery is not available for promotional items. Please use online payment."
                    .tr,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 14,
                  color: AppThemeData.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardDecoration(
    CartControllerProvider controller,
    PaymentGateway value,
    String image,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              controller.selectedPaymentMethod = value.name;
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0),
                    child: Image.asset(image),
                  ),
                ),
                const SizedBox(width: 10),
                value.name == "wallet"
                    ? Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.name.capitalizeString(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 16,
                                color: AppThemeData.grey900,
                              ),
                            ),
                            Text(
                              Constant.amountShow(
                                amount:
                                    controller.userModel.walletAmount == null
                                    ? '0.0'
                                    : controller.userModel.walletAmount
                                          .toString(),
                              ),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 16,
                                color: AppThemeData.primary300,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Expanded(
                        child: Text(
                          value.name.capitalizeString(),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                            color: AppThemeData.grey900,
                          ),
                        ),
                      ),
                const Expanded(child: SizedBox()),
                Radio(
                  value: value.name,
                  groupValue: controller.selectedPaymentMethod,
                  activeColor: AppThemeData.primary300,
                  onChanged: (value) {
                    controller.selectedPaymentMethod = value.toString();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UseWalletSection extends StatelessWidget {
  const _UseWalletSection({required this.controller});

  final CartControllerProvider controller;

  @override
  Widget build(BuildContext context) {
    final moneyRupees = controller.walletBalanceRupees;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeData.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeData.primary200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Use Wallet".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 15,
                    color: AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Wallet balance".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 14,
                    color: AppThemeData.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Constant.amountShow(amount: moneyRupees.toStringAsFixed(2)),
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 22,
                    color: AppThemeData.primary300,
                  ),
                ),
                if (controller.useWalletBalance &&
                    controller.walletToUse > 0 &&
                    controller.paymentGatewayAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "${Constant.amountShow(amount: controller.walletToUse.toStringAsFixed(2))} ${'from wallet'.tr}, ${Constant.amountShow(amount: controller.paymentGatewayAmount.toStringAsFixed(2))} ${'via payment'.tr}",
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 12,
                        color: AppThemeData.primary300,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: controller.useWalletBalance,
            onChanged: (value) async {
              await controller.setUseWalletBalance(value);
            },
            activeColor: AppThemeData.primary300,
          ),
        ],
      ),
    );
  }
}
