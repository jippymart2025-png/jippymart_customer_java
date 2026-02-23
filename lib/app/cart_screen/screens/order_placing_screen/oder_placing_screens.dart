import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/provider/order_placing_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class OrderPlacingScreen extends StatefulWidget {
  const OrderPlacingScreen({super.key});

  @override
  State<OrderPlacingScreen> createState() => _OrderPlacingScreenState();
}

class _OrderPlacingScreenState extends State<OrderPlacingScreen> {
  @override
  void initState() {
    super.initState();
    // After order placed: single GET /wallet via WalletProvider, then sync cart balance
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final wp = context.read<WalletProvider>();
        final cart = context.read<CartControllerProvider>();
        await wp.refreshWallet(force: true);
        if (!mounted) return;
        cart.syncWalletBalanceFromWallet(wp.moneyBalanceRupees);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<CartControllerProvider, OrderPlacingProvider>(
        builder: (context, cartControllerProvider, controller, _) {
          return WillPopScope(
            onWillPop: () async {
              cartControllerProvider.forceRefreshCart();
              return true;
            },
            child: Scaffold(
              backgroundColor: AppThemeData.surface,
              appBar: AppBar(
                backgroundColor: AppThemeData.surface,
                centerTitle: false,
                titleSpacing: 0,
              ),
              body: controller.isLoading
                  ? Constant.loader(message: "Preparing your order...".tr)
                  : (controller.isPlacing ||
                        (controller.orderModel.id != null &&
                            controller.orderModel.id.toString().isNotEmpty))
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order Placed".tr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppThemeData.grey900,
                              fontSize: 34,
                              fontFamily: AppThemeData.medium,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "Your delicious meal is on its way! Sit tight and we'll handle the rest."
                                .tr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppThemeData.grey600,
                              fontSize: 16,
                              fontFamily: AppThemeData.regular,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/ic_location.svg",
                                        colorFilter: ColorFilter.mode(
                                          AppThemeData.primary300,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Order ID".tr,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            color: AppThemeData.primary300,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    controller.orderModel.id.toString(),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.medium,
                                      color: AppThemeData.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              "assets/images/ic_timer.gif",
                              height: 140,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Placing your order".tr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppThemeData.grey900,
                              fontSize: 34,
                              fontFamily: AppThemeData.medium,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "Review your items and proceed to checkout for a delicious experience."
                                .tr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppThemeData.grey600,
                              fontSize: 16,
                              fontFamily: AppThemeData.regular,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/ic_location.svg",
                                        colorFilter: ColorFilter.mode(
                                          AppThemeData.primary300,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Delivery Address".tr,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            color: AppThemeData.primary300,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    controller.orderModel.address!
                                        .getFullAddress(),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.medium,
                                      color: AppThemeData.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/ic_book.svg",
                                        colorFilter: ColorFilter.mode(
                                          AppThemeData.primary300,
                                          BlendMode.srcIn,
                                        ),
                                        height: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Order Summary".tr,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            color: AppThemeData.primary300,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                        controller.orderModel.products!.length,
                                    itemBuilder: (context, index) {
                                      CartProductModel cartProductModel =
                                          controller
                                              .orderModel
                                              .products![index];
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${cartProductModel.quantity} x".tr,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              color: AppThemeData.grey900,
                                              fontSize: 14,
                                              fontFamily: AppThemeData.regular,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              "${cartProductModel.name}".tr,
                                              textAlign: TextAlign.start,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppThemeData.grey900,
                                                fontSize: 14,
                                                fontFamily: AppThemeData.regular,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              bottomNavigationBar: Consumer2<OrderProvider, DashBoardProvider>(
                builder: (context, orderProvider, dashBoardProvider, _) {
                  // Show Track Order button when order is placed (has ID)
                  final isOrderPlaced =
                      controller.isPlacing ||
                      (controller.orderModel.id != null &&
                          controller.orderModel.id.toString().isNotEmpty);

                  return Container(
                    color: AppThemeData.grey50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: isOrderPlaced
                          ? RoundedButtonFill(
                              title: "Track Order".tr,
                              height: 5.5,
                              color: AppThemeData.primary300,
                              textColor: AppThemeData.grey50,
                              fontSizes: 16,
                              onPress: () async {
                                // 🔑 CRITICAL: Force refresh orders before navigation
                                await orderProvider.getOrder(forceRefresh: true);

                                // Set orders tab as selected
                                dashBoardProvider.selectedIndex = 3;
                                dashBoardProvider.notifyListeners();

                                // Navigate to dashboard and ensure orders tab is initialized
                                Get.offAll(() => const DashBoardScreen());
                                
                                // 🔑 CRITICAL: Ensure orders are refreshed after navigation
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  // Refresh orders again after dashboard is built to ensure latest data
                                  orderProvider.getOrder(forceRefresh: true);
                                });
                              },
                            )
                          : RoundedButtonFill(
                              title: "Track Order".tr,
                              color: AppThemeData.primary300,
                              textColor: AppThemeData.grey50,
                              fontSizes: 16,
                              onPress: () async {
                                // 🔑 CRITICAL: Force refresh orders before navigation
                                await orderProvider.getOrder(forceRefresh: true);

                                // Set orders tab as selected
                                dashBoardProvider.selectedIndex = 3;
                                dashBoardProvider.notifyListeners();

                                // Navigate to dashboard and ensure orders tab is initialized
                                Get.offAll(() => const DashBoardScreen());
                                
                                // 🔑 CRITICAL: Ensure orders are refreshed after navigation
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  // Refresh orders again after dashboard is built to ensure latest data
                                  orderProvider.getOrder(forceRefresh: true);
                                });
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

