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
                  // 🔑 CRITICAL: Reset stuck processing flag before checking
                  // This handles cases where flag got stuck from previous failed attempt
                  // if (controller.isProcessingOrder) {
                  //   debugPrint(
                  //     "⚠️ Processing flag was stuck, resetting to allow retry",
                  //   );
                  //   controller.endOrderProcessing();
                  //   // Small delay to ensure state is updated
                  //   await Future.delayed(const Duration(milliseconds: 100));
                  // }

                  // Prevent duplicate clicks (check again after potential reset)
                  try {
                    // Show payment dialog FIRST - don't set processing flag yet
                    final paymentConfirmed = await controller
                        .showPaymentMethodDialog(context);
                    // Only set processing flag AFTER user confirms payment selection
                    if (paymentConfirmed == true &&
                        controller.selectedPaymentMethod.isNotEmpty) {
                      if (controller.isProcessingOrder) {
                        ShowToastDialog.showToast(
                          "Please wait, order is being processed...".tr,
                        );
                        return;
                      } else {
                        controller.startOrderProcessing();
                        controller.providerInitializer(context: context);
                        await controller.processPayment(controller, context);
                      }
                    } else {
                      // User cancelled payment selection or validation failed
                      // Ensure flag is reset (should already be reset, but double-check)
                      controller.endOrderProcessing();
                      debugPrint(
                        "Payment selection cancelled or validation failed",
                      );
                    }
                  } catch (e) {
                    controller.endOrderProcessing();
                    ShowToastDialog.showToast(
                      "An error occurred. Please try again.".tr,
                    );
                    debugPrint("Error in payment process: $e");
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
