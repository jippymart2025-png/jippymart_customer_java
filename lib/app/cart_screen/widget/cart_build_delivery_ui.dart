import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/constant/constant.dart' show Constant;
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum CartTheme { food, mart, mixed }

class CartThemeColors {
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color surface;
  final Color onSurface;

  const CartThemeColors({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.surface,
    required this.onSurface,
  });
}

/// Delivery fee display widget – all logic unchanged, UI refined.
Widget buildDeliveryFeeUI({
  required bool isFreeDelivery,
  required double originalFee,
  required double currentFee,
}) {
  final bool isFreeDeliveryWithExtraCharge =
      isFreeDelivery && currentFee > 0.0 && originalFee > 0.0;

  if (isFreeDelivery) {
    if (isFreeDeliveryWithExtraCharge) {
      return Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _freeTag(),
          _strikeText(Constant.amountShow(amount: originalFee.toString())),
          _normalPriceText(Constant.amountShow(amount: currentFee.toString())),
        ],
      );
    } else {
      return Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _freeTag(),
          _strikeText(Constant.amountShow(amount: originalFee.toString())),
          _normalPriceText(Constant.amountShow(amount: '0.00')),
        ],
      );
    }
  } else {
    return _normalPriceText(Constant.amountShow(amount: currentFee.toString()));
  }
}

Widget _freeTag() => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: const Color(0xFFE8F5E9),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'FREE',
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppThemeData.success400,
      letterSpacing: 0.5,
    ),
  ),
);

Widget _strikeText(String text) => Text(
  text,
  style: TextStyle(
    fontSize: 12,
    color: AppThemeData.grey400,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppThemeData.grey400,
  ),
);

Widget _normalPriceText(String text) => Text(
  text,
  style: TextStyle(
    fontSize: 13,
    fontFamily: AppThemeData.medium,
    color: AppThemeData.grey900,
  ),
);

// ─── TIPS DIALOG (logic preserved, UI refined) ───────────────────────────────

Widget tipsDialog(CartControllerProvider controller) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    insetPadding: const EdgeInsets.all(20),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    backgroundColor: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text('💝', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  'Custom Tip Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your generosity means a lot to our delivery partners',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey500,
              ),
            ),
            const SizedBox(height: 20),

            TextFieldWidget(
              title: 'Enter Amount'.tr,
              controller: controller.tipsController,
              textInputType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9]')),
              ],
              prefix: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 16,
                  ),
                ),
              ),
              hintText: '0',
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppThemeData.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.semiBold,
                          color: AppThemeData.grey700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (controller.tipsController.value.text.isEmpty) {
                        ShowToastDialog.showToast(
                          'Please enter a tip amount'.tr,
                        );
                      } else {
                        controller.deliveryTips = double.parse(
                          controller.tipsController.value.text,
                        );
                        controller.calculatePrice();
                        Get.back();
                      }
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppThemeData.primary300,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeData.primary300.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Add Tip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Legacy cardDecoration kept for any other usages
Widget cardDecoration(
  CartControllerProvider controller,
  PaymentGateway value,
  dynamic themeChange,
  String image,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Container(
      width: 40,
      height: 40,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0),
        child: image == ''
            ? Container(color: AppThemeData.grey100)
            : Image.asset(image),
      ),
    ),
  );
}
