import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

Widget cartNavigationBarWidget(BuildContext context) {
  return Consumer<CartControllerProvider>(
    builder: (context, controller, _) {
      // Get bottom safe area padding to ensure button is above system UI
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: 20 + bottomPadding, // Add safe area bottom padding
        ),
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
                    controller.providerInitializer(context: context);
                    await controller.processPayment(controller, context);
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
