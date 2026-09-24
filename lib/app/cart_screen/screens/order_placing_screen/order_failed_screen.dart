import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:provider/provider.dart';

/// Shown when the backend reports a payment that was NOT successfully completed
/// (e.g. paymentStatus = PENDING / FAILED). Mirrors the OrderPlacingScreen flow
/// but with a failure UI and a way to retry or go home.
class OrderFailedScreen extends StatelessWidget {
  const OrderFailedScreen({super.key, this.orderId, this.message});

  final String? orderId;
  final String? message;

  void _retry(BuildContext context) {
    try {
      context.read<CartControllerProvider>().forceRefreshCart();
    } catch (_) {}
    Get.back();
  }

  void _goHome(BuildContext context) {
    try {
      context.read<CartControllerProvider>().forceRefreshCart();
    } catch (_) {}
    Get.offAll(() => const DashBoardScreen());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black54,
            size: 18,
          ),
          onPressed: () => _retry(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFDE7E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Order Failed',
              style: TextStyle(
                fontSize: 24,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              (message != null && message!.isNotEmpty)
                  ? message!
                  : 'We could not confirm your payment. Please try again.',
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (orderId != null && orderId!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Reference: #$orderId',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _retry(context),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppThemeData.primary300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _goHome(context),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppThemeData.grey100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Go to Home',
                    style: TextStyle(
                      color: AppThemeData.grey800,
                      fontSize: 16,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}