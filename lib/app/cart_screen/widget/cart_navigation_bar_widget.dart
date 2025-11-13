import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/payment/createRazorPayOrderModel.dart';
import 'package:jippymart_customer/payment/rozorpayConroller.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget cartNavigationBarWidget(
  CartControllerProvider controller,
  BuildContext context,
) {
  return Container(
    decoration: BoxDecoration(
      color: AppThemeData.grey50,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        children: [
          Expanded(
            child: RoundedButtonFill(
              textColor: AppThemeData.surface,
              isEnabled: true,
              title: controller.isProcessingOrder
                  ? "Processing...".tr
                  : "Place Order".tr,
              height: 5,
              color: AppThemeData.primary300,
              fontSizes: 16,
              onPress: () async {
                if (controller.isProcessingOrder) {
                  ShowToastDialog.showToast(
                    "Please wait, order is being processed...".tr,
                  );
                  return;
                }
                // print("${controller.vendorModel.value.author.toString()} "
                //     " ${controller.vendorModel.value.authorName.toString()}  ${controller.vendorModel.value.categoryTitle.toString()}  vendorModel.value.author ");

                await controller.showPaymentMethodDialog(context);
                if (controller.selectedPaymentMethod.isNotEmpty) {
                  await _processPayment(controller, context);
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _processPayment(
  CartControllerProvider controller,
  BuildContext context,
) async {
  // Run bulletproof validation
  final canProceed = await controller.validateAndPlaceOrderBulletproof(context);
  if (!canProceed) {
    return;
  }
  // Validate coupon and discount amounts
  if ((controller.couponAmount >= 1) &&
      (controller.couponAmount > controller.totalAmount)) {
    ShowToastDialog.showToast(
      "The total price must be greater than or equal to the coupon discount value for the code to apply. Please review your cart total."
          .tr,
    );
    return;
  }
  if ((controller.specialDiscountAmount >= 1) &&
      (controller.specialDiscountAmount > controller.totalAmount)) {
    ShowToastDialog.showToast(
      "The total price must be greater than or equal to the special discount value for the code to apply. Please review your cart total."
          .tr,
    );
    return;
  }
  // Process based on selected payment method
  if (controller.selectedPaymentMethod == PaymentGateway.cod.name) {
    controller.placeOrder(context);
  } else if (controller.selectedPaymentMethod == PaymentGateway.razorpay.name) {
    RazorPayController()
        .createOrderRazorPay(
          amount: double.parse(controller.totalAmount.toString()),
          razorpayModel: controller.razorPayModel,
        )
        .then((value) async {
          if (value == null) {
            Get.back();
            ShowToastDialog.showToast(
              "Something went wrong, please contact admin.".tr,
            );
          } else {
            CreateRazorPayOrderModel result = value;
            controller.openCheckout(amount: value.amount, orderId: result.id);
          }
        });
  } else {
    ShowToastDialog.showToast("Please select payment method".tr);
  }
}
