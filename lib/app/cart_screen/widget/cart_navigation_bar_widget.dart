import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/payment/createRazorPayOrderModel.dart';
import 'package:jippymart_customer/payment/rozorpayConroller.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

Widget cartNavigationBarWidget(BuildContext context) {
  return Consumer<CartControllerProvider>(
    builder: (context, controller, _) {
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
                    await controller.showPaymentMethodDialog(context);
                    if (controller.selectedPaymentMethod.isNotEmpty) {
                      // await controller.forceRefreshCart();
                      controller.providerInitializer(context: context);
                      await controller.processPayment(controller, context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
