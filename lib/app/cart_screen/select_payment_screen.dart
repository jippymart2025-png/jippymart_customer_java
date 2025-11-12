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
                  if (controller.cashOnDeliverySettingModel.value.isEnabled ==
                      true)
                    Container(
                      decoration: ShapeDecoration(
                        color: AppThemeData.grey50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x07000000),
                            blurRadius: 20,
                            offset: Offset(0, 0),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Visibility(
                              visible: false, // Hide wallet option
                              child: cardDecoration(
                                controller,
                                PaymentGateway.wallet,
                                "assets/images/ic_wallet.png",
                              ),
                            ),
                            Visibility(
                              visible:
                                  controller
                                          .cashOnDeliverySettingModel
                                          .value
                                          .isEnabled ==
                                      true &&
                                  controller.subTotal <= 599 &&
                                  !controller.hasPromotionalItems(),
                              child: cardDecoration(
                                controller,
                                PaymentGateway.cod,
                                "assets/images/ic_cash.png",
                              ),
                            ),
                            Visibility(
                              visible:
                                  controller
                                          .cashOnDeliverySettingModel
                                          .value
                                          .isEnabled ==
                                      true &&
                                  controller.subTotal > 599,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppThemeData.grey100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppThemeData.grey600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Cash on Delivery is not available for orders above ₹599"
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
                            ),
                            Visibility(
                              visible:
                                  controller
                                          .cashOnDeliverySettingModel
                                          .value
                                          .isEnabled ==
                                      true &&
                                  controller.subTotal <= 599 &&
                                  controller.hasPromotionalItems(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppThemeData.grey100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppThemeData.grey600,
                                      size: 20,
                                    ),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (controller.cashOnDeliverySettingModel.value.isEnabled ==
                      true)
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
                  Container(
                    decoration: ShapeDecoration(
                      color: AppThemeData.grey50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x07000000),
                          blurRadius: 20,
                          offset: Offset(0, 0),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Visibility(
                            visible:
                                controller.razorPayModel.value.isEnabled ==
                                true,
                            child: cardDecoration(
                              controller,
                              PaymentGateway.razorpay,
                              "assets/images/razorpay.png",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppThemeData.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RoundedButtonFill(
                title:
                    "${'Pay Now'.tr} | ${Constant.amountShow(amount: controller.totalAmount.toString())}"
                        .tr,
                height: 5,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                fontSizes: 16,
                onPress: () async {
                  Get.back();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget cardDecoration(
    CartControllerProvider controller,
    PaymentGateway value,
    String image,
  ) {
    return Obx(
      () => Padding(
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
                      padding: EdgeInsets.all(
                        value.name == "payFast" ? 0 : 8.0,
                      ),
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
      ),
    );
  }
}
