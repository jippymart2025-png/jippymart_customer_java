import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/cart_screen/select_payment_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

Widget cartNavigationBarWidget(BuildContext context) {
  return Consumer<CartControllerProvider>(
    builder: (context, controller, _) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      final totalAmount = controller.totalAmount;
      final isProcessing = controller.isProcessingOrder;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
          child: Row(
            children: [
              // ── Cart summary (item count + amount) ──────────────────────
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${HomeProvider.cartItem.length} item${HomeProvider.cartItem.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      Constant.amountShow(
                        amount: totalAmount.toStringAsFixed(2),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.grey900,
                      ),
                    ),
                    if (controller.useWalletBalance &&
                        controller.walletToUse > 0)
                      Text(
                        'Wallet: -${Constant.amountShow(amount: controller.walletToUse.toStringAsFixed(2))}',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: AppThemeData.regular,
                          color: AppThemeData.primary300,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Place Order Button ────────────────────────────────────────
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: isProcessing
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const SelectPaymentScreen(),
                            ),
                          );
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      color: isProcessing
                          ? AppThemeData.grey300
                          : AppThemeData.primary300,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isProcessing
                          ? []
                          : [
                              BoxShadow(
                                color: AppThemeData.primary300.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isProcessing) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          isProcessing ? 'Processing...' : 'Place Order',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (!isProcessing) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
