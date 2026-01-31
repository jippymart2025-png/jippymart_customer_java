// import 'dart:convert';
//
// import 'package:jippymart_customer/app/auth_screen/login_screen.dart';
// import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/order_details_screen.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/order_model.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:jippymart_customer/utils/network_image_widget.dart';
// import 'package:jippymart_customer/utils/utils/app_constant.dart';
// import 'package:jippymart_customer/utils/utils/color_const.dart';
// import 'package:jippymart_customer/utils/utils/common.dart';
// import 'package:jippymart_customer/utils/utils/image_const.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:jippymart_customer/widget/my_separator.dart';
// import 'package:jippymart_customer/widgets/app_loading_widget.dart';
// import 'package:jippymart_customer/utils/fire_store_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../auth_screen/phone_number_screen.dart';
//
// class OrderScreen extends StatelessWidget {
//   const OrderScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<DashBoardProvider, OrderProvider>(
//       builder: (context, dashBoardProvider, controller, _) {
//         return Consumer<OrderProvider>(
//           builder: (context, controller, _) {
//             return Scaffold(
//               body: Container(
//                 decoration: BoxDecoration(
//                   image: DecorationImage(
//                     image: AssetImage(ImageConst.backgroundImage),
//                     fit: BoxFit.cover, // can use contain, fill, repeat
//                   ),
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.only(
//                     top: MediaQuery.of(context).viewPadding.top,
//                   ),
//                   child: controller.isLoading
//                       ? const OrderLoadingWidget(
//                           message: "🍽️ Loading Your Orders",
//                         )
//                       : Constant.userModel == null
//                       ? Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 "assets/images/login.gif",
//                                 height: 140,
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 "Please Log In to Continue".tr,
//                                 style: TextStyle(
//                                   color: AppThemeData.grey800,
//                                   fontSize: 22,
//                                   fontFamily: AppThemeData.semiBold,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 "You're not logged in. Please sign in to access your account and explore all features."
//                                     .tr,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: AppThemeData.grey500,
//                                   fontSize: 16,
//                                   fontFamily: AppThemeData.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               RoundedButtonFill(
//                                 title: "Log in".tr,
//                                 width: 55,
//                                 height: 5.5,
//                                 color: AppThemeData.primary300,
//                                 textColor: AppThemeData.grey50,
//                                 onPress: () async {
//                                   Get.offAll(() => PhoneNumberScreen());
//                                 },
//                               ),
//                             ],
//                           ),
//                         )
//                       : DefaultTabController(
//                           length: 6,
//                           child: Column(
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             "My Order".tr,
//                                             style: TextStyle(
//                                               fontSize: 24,
//                                               color: AppThemeData.grey900,
//                                               fontFamily: AppThemeData.semiBold,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               Expanded(
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 6,
//                                           horizontal: 10,
//                                         ),
//                                         decoration: ShapeDecoration(
//                                           color: AppThemeData.grey100,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               120,
//                                             ),
//                                           ),
//                                         ),
//                                         child: TabBar(
//                                           indicator: BoxDecoration(
//                                             borderRadius: BorderRadius.circular(
//                                               50,
//                                             ), // Creates border
//                                             color: AppThemeData.primary300,
//                                           ),
//                                           labelColor: AppThemeData.grey50,
//                                           isScrollable: true,
//                                           tabAlignment: TabAlignment.start,
//                                           indicatorWeight: 0.5,
//                                           unselectedLabelColor:
//                                               AppThemeData.grey900,
//                                           dividerColor: Colors.transparent,
//                                           indicatorSize:
//                                               TabBarIndicatorSize.tab,
//                                           tabs: [
//                                             Padding(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                     horizontal: 18,
//                                                   ),
//                                               child: Tab(text: 'All'.tr),
//                                             ),
//                                             Tab(text: 'New Orders'.tr),
//                                             Tab(text: 'In Progress'.tr),
//                                             Tab(text: 'Delivered'.tr),
//                                             Tab(text: 'Cancelled'.tr),
//                                             Tab(text: 'Rejected'.tr),
//                                           ],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       Expanded(
//                                         child: TabBarView(
//                                           children: [
//                                             controller.allList.isEmpty
//                                                 ? Constant.showEmptyView(
//                                                     message:
//                                                         "Order Not Found".tr,
//                                                   )
//                                                 : RefreshIndicator(
//                                                     onRefresh: () =>
//                                                         controller.getOrder(),
//                                                     child: ListView.builder(
//                                                       itemCount: controller
//                                                           .allList
//                                                           .length,
//                                                       shrinkWrap: true,
//                                                       padding: EdgeInsets.zero,
//                                                       itemBuilder:
//                                                           (context, index) {
//                                                             OrderModel
//                                                             orderModel = controller
//                                                                 .allList[index];
//                                                             return itemView(
//                                                               context,
//                                                               orderModel,
//                                                               controller,
//                                                             );
//                                                           },
//                                                     ),
//                                                   ),
//                                             controller.newOrderList.isEmpty
//                                                 ? Constant.showEmptyView(
//                                                     message:
//                                                         "Order Not Found".tr,
//                                                   )
//                                                 : RefreshIndicator(
//                                                     onRefresh: () =>
//                                                         controller.getOrder(),
//                                                     child: ListView.builder(
//                                                       itemCount: controller
//                                                           .newOrderList
//                                                           .length,
//                                                       shrinkWrap: true,
//                                                       padding: EdgeInsets.zero,
//                                                       itemBuilder: (context, index) {
//                                                         OrderModel
//                                                         orderModel = controller
//                                                             .newOrderList[index];
//                                                         return itemView(
//                                                           context,
//                                                           orderModel,
//                                                           controller,
//                                                         );
//                                                       },
//                                                     ),
//                                                   ),
//                                             controller.inProgressList.isEmpty
//                                                 ? Constant.showEmptyView(
//                                                     message:
//                                                         "Order Not Found".tr,
//                                                   )
//                                                 : RefreshIndicator(
//                                                     onRefresh: () =>
//                                                         controller.getOrder(),
//                                                     child: ListView.builder(
//                                                       itemCount: controller
//                                                           .inProgressList
//                                                           .length,
//                                                       shrinkWrap: true,
//                                                       padding: EdgeInsets.zero,
//                                                       itemBuilder: (context, index) {
//                                                         OrderModel
//                                                         orderModel = controller
//                                                             .inProgressList[index];
//                                                         return itemView(
//                                                           context,
//                                                           orderModel,
//                                                           controller,
//                                                         );
//                                                       },
//                                                     ),
//                                                   ),
//                                             controller.deliveredList.isEmpty
//                                                 ? Constant.showEmptyView(
//                                                     message:
//                                                         "Order Not Found".tr,
//                                                   )
//                                                 : RefreshIndicator(
//                                                     onRefresh: () =>
//                                                         controller.getOrder(),
//                                                     child: ListView.builder(
//                                                       itemCount: controller
//                                                           .deliveredList
//                                                           .length,
//                                                       shrinkWrap: true,
//                                                       padding: EdgeInsets.zero,
//                                                       itemBuilder: (context, index) {
//                                                         OrderModel
//                                                         orderModel = controller
//                                                             .deliveredList[index];
//                                                         return itemView(
//                                                           context,
//                                                           orderModel,
//                                                           controller,
//                                                         );
//                                                       },
//                                                     ),
//                                                   ),
//                                             controller.cancelledList.isEmpty
//                                                 ? Constant.showEmptyView(
//                                                     message:
//                                                         "Order Not Found".tr,
//                                                   )
//                                                 : RefreshIndicator(
//                                                     onRefresh: () =>
//                                                         controller.getOrder(),
//                                                     child: ListView.builder(
//                                                       itemCount: controller
//                                                           .cancelledList
//                                                           .length,
//                                                       shrinkWrap: true,
//                                                       padding: EdgeInsets.zero,
//                                                       itemBuilder: (context, index) {
//                                                         OrderModel
//                                                         orderModel = controller
//                                                             .cancelledList[index];
//                                                         return itemView(
//                                                           context,
//                                                           orderModel,
//                                                           controller,
//                                                         );
//                                                       },
//                                                     ),
//                                                   ),
//                                             controller.rejectedList.isEmpty
//                                                 ? Constant.showEmptyView(
//                                                     message:
//                                                         "Order Not Found".tr,
//                                                   )
//                                                 : RefreshIndicator(
//                                                     onRefresh: () =>
//                                                         controller.getOrder(),
//                                                     child: ListView.builder(
//                                                       itemCount: controller
//                                                           .rejectedList
//                                                           .length,
//                                                       shrinkWrap: true,
//                                                       padding: EdgeInsets.zero,
//                                                       itemBuilder: (context, index) {
//                                                         OrderModel
//                                                         orderModel = controller
//                                                             .rejectedList[index];
//                                                         return itemView(
//                                                           context,
//                                                           orderModel,
//                                                           controller,
//                                                         );
//                                                       },
//                                                     ),
//                                                   ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   itemView(
//     BuildContext context,
//     OrderModel orderModel,
//     OrderProvider controller,
//   ) {
//     return Consumer<OrderDetailsProvider>(
//       builder: (context, orderDetailsProvider, _) {
//         print("itemView ${orderModel.id.toString()} ");
//         return GestureDetector(
//           onTap: () async {
//             double? surgeFee = await fetchOrderSergeFee(orderModel.id ?? '');
//             orderDetailsProvider.initFunction(orderModels: orderModel);
//             Get.to(OrderDetailsScreen(surgeFee: surgeFee));
//           },
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 5),
//             child: Card(
//               elevation: 4, // 👈 Add shadow
//               color: ColorConst.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         ClipRRect(
//                           borderRadius: const BorderRadius.all(
//                             Radius.circular(16),
//                           ),
//                           child: Stack(
//                             children: [
//                               orderModel.vendor?.photo != null &&
//                                       orderModel.vendor!.photo!.isNotEmpty
//                                   ? NetworkImageWidget(
//                                       imageUrl: orderModel.vendor!.photo!,
//                                       fit: BoxFit.cover,
//                                       height: Responsive.height(10, context),
//                                       width: Responsive.width(20, context),
//                                     )
//                                   : Container(
//                                       height: Responsive.height(10, context),
//                                       width: Responsive.width(20, context),
//                                       decoration: BoxDecoration(
//                                         color: AppThemeData.grey200,
//                                         borderRadius: BorderRadius.circular(16),
//                                       ),
//                                       child: Icon(
//                                         Icons.store,
//                                         color: AppThemeData.grey500,
//                                         size: Responsive.width(5, context),
//                                       ),
//                                     ),
//                               Container(
//                                 height: Responsive.height(10, context),
//                                 width: Responsive.width(20, context),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: const Alignment(0.00, 1.00),
//                                     end: const Alignment(0, -1),
//                                     colors: [
//                                       Colors.black.withOpacity(0),
//                                       AppThemeData.grey900,
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 orderModel.status.toString(),
//                                 textAlign: TextAlign.right,
//                                 style: TextStyle(
//                                   color: Constant.statusColor(
//                                     status: orderModel.status.toString(),
//                                   ),
//                                   fontFamily: AppThemeData.semiBold,
//                                   fontWeight: FontWeight.w500,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 orderModel.vendor?.title?.toString() ??
//                                     "Jippy Mart",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: AppThemeData.grey900,
//                                   fontFamily: AppThemeData.medium,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 orderModel.createdAt != null
//                                     ? Constant.timestampToDateTime(
//                                         orderModel.createdAt!,
//                                       )
//                                     : "Order placed",
//                                 style: TextStyle(
//                                   color: AppThemeData.grey600,
//                                   fontFamily: AppThemeData.medium,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     // In the OrderScreen's itemView method, replace the current "Total to Pay" section:
//                     FutureBuilder<double>(
//                       future: calculateOrderTotalInList(orderModel),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   "Total to Pay",
//                                   style: TextStyle(
//                                     color: AppThemeData.grey900,
//                                     fontFamily: AppThemeData.semiBold,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ),
//                               Container(
//                                 width: 60,
//                                 height: 16,
//                                 decoration: BoxDecoration(
//                                   color: AppThemeData.grey200,
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                               ),
//                             ],
//                           );
//                         } else if (snapshot.hasData) {
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   "Total to Pay",
//                                   style: TextStyle(
//                                     color: AppThemeData.grey900,
//                                     fontFamily: AppThemeData.semiBold,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ),
//                               Text(
//                                 Constant.amountShow(
//                                   amount: snapshot.data!.toString(),
//                                 ),
//                                 style: TextStyle(
//                                   color: AppThemeData.primary300,
//                                   fontFamily: AppThemeData.semiBold,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           );
//                         } else {
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   "Total to Pay",
//                                   style: TextStyle(
//                                     color: AppThemeData.grey900,
//                                     fontFamily: AppThemeData.semiBold,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ),
//                               Text(
//                                 Constant.amountShow(
//                                   amount: orderModel.toPayAmount.toString(),
//                                 ),
//                                 style: TextStyle(
//                                   color: AppThemeData.primary300,
//                                   fontFamily: AppThemeData.semiBold,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           );
//                         }
//                       },
//                     ),
//                     // Row(
//                     //   children: [
//                     //     Expanded(
//                     //       child: Text(
//                     //         "Total to Pay",
//                     //         style: TextStyle(
//                     //           color: AppThemeData.grey900,
//                     //           fontFamily: AppThemeData.semiBold,
//                     //           fontWeight: FontWeight.w600,
//                     //           fontSize: 16,
//                     //         ),
//                     //       ),
//                     //     ),
//                     //     Text(
//                     //       //finded
//                     //       Constant.amountShow(
//                     //         amount: orderModel.toPayAmount.toString(),
//                     //       ),
//                     //       style: TextStyle(
//                     //         color: AppThemeData.primary300,
//                     //         fontFamily: AppThemeData.semiBold,
//                     //         fontWeight: FontWeight.w600,
//                     //         fontSize: 16,
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       child: MySeparator(color: AppThemeData.grey200),
//                     ),
//
//                     ///////////
//                     Row(
//                       children: [
//                         orderModel.status == Constant.orderCompleted
//                             ? Expanded(
//                                 child: InkWell(
//                                   onTap: () {
//                                     if (orderModel.products != null) {
//                                       for (var element
//                                           in orderModel.products!) {
//                                         controller.addToCart(
//                                           cartProductModel: element,
//                                         );
//                                         ShowToastDialog.showToast(
//                                           "Item Added In a cart".tr,
//                                         );
//                                       }
//                                     }
//                                   },
//                                   child: Text(
//                                     "Reorder".tr,
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: AppThemeData.primary300,
//                                       fontFamily: AppThemeData.semiBold,
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             : orderModel.status == Constant.orderShipped ||
//                                   orderModel.status == Constant.orderInTransit
//                             ? Consumer<LiveTrackingProvider>(
//                                 builder: (context, liveTrackingProvider, _) {
//                                   return Expanded(
//                                     child: InkWell(
//                                       onTap: () {
//                                         liveTrackingProvider.initFunction(
//                                           orderModel: orderModel,
//                                         );
//                                         Get.to(const LiveTrackingScreen());
//                                       },
//                                       child: Text(
//                                         "Track Order".tr,
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: AppThemeData.primary300,
//                                           fontFamily: AppThemeData.semiBold,
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               )
//                             : const SizedBox(),
//                         Expanded(
//                           child: Consumer<OrderDetailsProvider>(
//                             builder: (context, orderDetailsProvider, _) {
//                               return InkWell(
//                                 onTap: () async {
//                                   double? surgeFee = await fetchOrderSergeFee(
//                                     orderModel.id ?? '',
//                                   );
//                                   orderDetailsProvider.initFunction(
//                                     orderModels: orderModel,
//                                   );
//                                   Get.to(
//                                     OrderDetailsScreen(surgeFee: surgeFee),
//                                   );
//                                 },
//                                 child: Text(
//                                   "View Details".tr,
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: AppThemeData.grey900,
//                                     fontFamily: AppThemeData.semiBold,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<double> calculateOrderTotalInList(OrderModel order) async {
//     final vendor =
//         order.vendor ??
//         VendorModel(
//           title: "Jippy Mart",
//           location: "Jippy Mart Store",
//           phonenumber: "Contact Support",
//           isSelfDelivery: false,
//           deliveryCharge: DeliveryCharge(
//             baseDeliveryCharge: 23.0,
//             itemTotalThreshold: 299.0,
//             freeDeliveryDistanceKm: 7.0,
//             perKmChargeAboveFreeDistance: 8.0,
//           ),
//           latitude: 0.0,
//           longitude: 0.0,
//           vType: 'mart',
//         );
//     final deliveryCharge = vendor.deliveryCharge ?? DeliveryCharge();
//     final totalDistance = order.vendor != null
//         ? Constant.calculateDistance(
//             vendor.latitude ?? 0.0,
//             vendor.longitude ?? 0.0,
//             order.address?.location?.latitude ?? 0.0,
//             order.address?.location?.longitude ?? 0.0,
//           )
//         : 0.0;
//     // Reuse the same calculation logic from OrderDetailsScreen
//     double subTotal = 0.0;
//     double deliveryCharges = 0.0;
//     double originalDeliveryFee = 0.0;
//     double couponAmount = 0.0;
//     double specialDiscountAmount = 0.0;
//     double taxAmount = 0.0;
//     double deliveryTips = double.tryParse(order.tipAmount ?? '0') ?? 0.0;
//     double totalAmount = 0.0;
//     if (order.products != null) {
//       for (var element in order.products!) {
//         final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
//         final discountPriceValue =
//             double.tryParse(element.discountPrice.toString()) ?? 0.0;
//         final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
//         final isPricePromotional =
//             priceValue > 0 &&
//             discountPriceValue > 0 &&
//             priceValue < discountPriceValue;
//         final isPromotional = hasPromo || isPricePromotional;
//         double itemPrice;
//         if (isPromotional) {
//           itemPrice = priceValue < discountPriceValue
//               ? priceValue
//               : discountPriceValue;
//         } else if (discountPriceValue <= 0) {
//           itemPrice = priceValue;
//         } else {
//           itemPrice = discountPriceValue;
//         }
//         final quantity = double.parse(element.quantity.toString());
//         final extrasPrice = double.parse(element.extrasPrice.toString());
//         final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
//         subTotal += itemTotal;
//       }
//     }
//     // Delivery charges calculation (same as OrderDetailsScreen)
//     const double fallbackThreshold = 299.0;
//     const double fallbackBaseCharge = 23.0;
//     const double fallbackFreeKm = 5.0;
//     const double fallbackPerKm = 7.0;
//
//     final double threshold =
//         (deliveryCharge.itemTotalThreshold ?? fallbackThreshold).toDouble();
//     final double baseCharge =
//         (deliveryCharge.baseDeliveryCharge ?? fallbackBaseCharge).toDouble();
//     final double freeKm =
//         (deliveryCharge.freeDeliveryDistanceKm ?? fallbackFreeKm).toDouble();
//     final double perKm =
//         (deliveryCharge.perKmChargeAboveFreeDistance ?? fallbackPerKm)
//             .toDouble();
//
//     final hasPromotionalItems = (order.products ?? []).any((item) {
//       final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
//       final discountPriceValue =
//           double.tryParse(item.discountPrice.toString()) ?? 0.0;
//       final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
//       final isPricePromotional =
//           priceValue > 0 &&
//           discountPriceValue > 0 &&
//           priceValue < discountPriceValue;
//       return hasPromo || isPricePromotional;
//     });
//
//     if (vendor.isSelfDelivery == true &&
//         Constant.isSelfDeliveryFeature == true) {
//       deliveryCharges = 0.0;
//       originalDeliveryFee = 0.0;
//     } else if (hasPromotionalItems) {
//       final promotionalItems = (order.products ?? []).where((item) {
//         final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
//         final discountPriceValue =
//             double.tryParse(item.discountPrice.toString()) ?? 0.0;
//         final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
//         final isPricePromotional =
//             priceValue > 0 &&
//             discountPriceValue > 0 &&
//             priceValue < discountPriceValue;
//         return hasPromo || isPricePromotional;
//       }).toList();
//
//       if (promotionalItems.isNotEmpty) {
//         final firstPromoItem = promotionalItems.first;
//         double promoFreeKm = 3.0;
//         double promoExtraKmCharge = fallbackPerKm;
//         const double promoBaseCharge = fallbackBaseCharge;
//
//         try {
//           final promoDetails =
//               await FireStoreUtils.getActivePromotionForProduct(
//                 productId: firstPromoItem.id ?? '',
//                 restaurantId: firstPromoItem.vendorID ?? '',
//               );
//
//           if (promoDetails != null) {
//             promoFreeKm =
//                 (promoDetails['free_delivery_km'] as num?)?.toDouble() ??
//                 promoFreeKm;
//             promoExtraKmCharge =
//                 (promoDetails['extra_km_charge'] as num?)?.toDouble() ??
//                 promoExtraKmCharge;
//           }
//         } catch (_) {}
//
//         if (totalDistance <= promoFreeKm) {
//           deliveryCharges = 0.0;
//           originalDeliveryFee = promoBaseCharge;
//         } else {
//           double extraKm = (totalDistance - promoFreeKm).ceilToDouble();
//           deliveryCharges = extraKm * promoExtraKmCharge;
//           originalDeliveryFee = deliveryCharges;
//         }
//       }
//     }
//
//     if (deliveryCharges == 0.0 && originalDeliveryFee == 0.0) {
//       if (subTotal < threshold) {
//         if (totalDistance <= freeKm) {
//           deliveryCharges = baseCharge;
//           originalDeliveryFee = baseCharge;
//         } else {
//           double extraKm = (totalDistance - freeKm).ceilToDouble();
//           deliveryCharges = baseCharge + (extraKm * perKm);
//           originalDeliveryFee = deliveryCharges;
//         }
//       } else {
//         if (totalDistance <= freeKm) {
//           deliveryCharges = 0.0;
//           originalDeliveryFee = baseCharge;
//         } else {
//           double extraKm = (totalDistance - freeKm).ceilToDouble();
//           deliveryCharges = extraKm * perKm;
//           originalDeliveryFee = baseCharge + deliveryCharges;
//         }
//       }
//     }
//
//     // Coupon discount
//     if (hasPromotionalItems) {
//       couponAmount = 0.0;
//     } else if (order.couponId != null &&
//         order.couponId!.isNotEmpty &&
//         order.discount != null) {
//       couponAmount = double.tryParse(order.discount.toString()) ?? 0.0;
//     } else {
//       couponAmount = 0.0;
//     }
//
//     // Special discount
//     if (order.specialDiscount != null &&
//         order.specialDiscount!['special_discount'] != null) {
//       specialDiscountAmount =
//           double.tryParse(
//             order.specialDiscount!['special_discount'].toString(),
//           ) ??
//           0.0;
//     }
//
//     // Taxes
//     // 🔑 FIXED: Calculate tax on base delivery charge + extra km charges
//     // When delivery is free (above ₹299) but distance exceeds free km:
//     // - Customer pays only extra km charge (e.g., ₹14 for 2 km)
//     // - But tax should be calculated on base charge (₹23) + extra km (₹14) = ₹37
//     // originalDeliveryFee already contains base + extra km, so always use it when available
//     final double taxableDeliveryFee = originalDeliveryFee > 0
//         ? originalDeliveryFee
//         : (deliveryCharges > 0 ? deliveryCharges : 0.0);
//
//     print(
//       '[TAX_CALC] Order Screen List - Delivery charges (customer pays): ₹$deliveryCharges, Original fee (base + extra km): ₹$originalDeliveryFee, Taxable fee: ₹$taxableDeliveryFee',
//     );
//
//     double sgst = subTotal * 0.05;
//     double gst = taxableDeliveryFee * 0.18;
//     sgst = sgst.isNaN ? 0.0 : sgst;
//     gst = gst.isNaN ? 0.0 : gst;
//     taxAmount = sgst + gst;
//     print("taxAmount = $taxAmount (SGST: $sgst, GST: $gst)");
//
//     if (taxAmount == 0.0) {
//       double sgstFallback = subTotal * 0.05; // 5% on subtotal
//       double gstFallback = taxableDeliveryFee > 0
//           ? taxableDeliveryFee * 0.18 // 18% on delivery charges or base charge (even when free delivery)
//           : 0.0;
//       taxAmount = sgstFallback + gstFallback;
//       print(
//         '[TAX_CALC] Order Screen List - Fallback tax applied → SGST (5% of ₹$subTotal): ₹$sgstFallback, GST (18% of ₹$taxableDeliveryFee): ₹$gstFallback, Total: ₹$taxAmount',
//       );
//     }
//     if (taxAmount.isNaN) taxAmount = 0.0;
//
//     // Check free delivery
//     bool isFreeDelivery = false;
//     if (hasPromotionalItems) {
//       // Free promo delivery already captured above via deliveryCharges/originalDeliveryFee
//       if (deliveryCharges == 0.0 && originalDeliveryFee > 0.0) {
//         isFreeDelivery = true;
//       }
//     } else {
//       if (subTotal >= threshold && totalDistance <= freeKm) {
//         isFreeDelivery = true;
//       }
//     }
//
//     totalAmount =
//         (subTotal - couponAmount - specialDiscountAmount) +
//         taxAmount +
//         (isFreeDelivery ? 0.0 : deliveryCharges) +
//         deliveryTips;
//
//     return totalAmount;
//   }
//
//   // Helper function to calculate the 'To Pay' value for an order
//   double calculateOrderTotal(OrderModel order) {
//     double subTotal = 0.0;
//     double specialDiscountAmount = 0.0;
//     double taxAmount = 0.0;
//     double totalAmount = 0.0;
//
//     print('DEBUG: Order Screen - Starting calculation for order: ${order.id}');
//     print(
//       'DEBUG: Order Screen - Total products: ${order.products?.length ?? 0}',
//     );
//
//     // Calculate subtotal using promotional prices if available
//     if (order.products != null) {
//       for (var element in order.products!) {
//         print('DEBUG: Order Screen - Processing product: ${element.name}');
//         print('DEBUG: Order Screen - Product ID: ${element.id}');
//         print('DEBUG: Order Screen - Price: ${element.price}');
//         print('DEBUG: Order Screen - DiscountPrice: ${element.discountPrice}');
//         print('DEBUG: Order Screen - PromoId: ${element.promoId}');
//
//         // Check if this item has a promotional price
//         final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
//         print('DEBUG: Order Screen - Has promo: $hasPromo');
//
//         double itemPrice;
//         if (hasPromo) {
//           // Use promotional price for calculations
//           itemPrice = double.parse(element.price.toString());
//           print('DEBUG: Order Screen - Using promotional price: $itemPrice');
//         } else if (double.parse(element.discountPrice.toString()) <= 0) {
//           // No promotion, no discount - use regular price
//           itemPrice = double.parse(element.price.toString());
//           print('DEBUG: Order Screen - Using regular price: $itemPrice');
//         } else {
//           // Regular discount (non-promo) - use discount price
//           itemPrice = double.parse(element.discountPrice.toString());
//           print('DEBUG: Order Screen - Using discount price: $itemPrice');
//         }
//
//         final quantity = double.parse(element.quantity.toString());
//         final extrasPrice = double.parse(element.extrasPrice.toString());
//
//         final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
//         subTotal += itemTotal;
//
//         print(
//           'DEBUG: Order Screen - Item total: $itemTotal, Running subtotal: $subTotal',
//         );
//       }
//     }
//
//     if (order.specialDiscount != null &&
//         order.specialDiscount!['special_discount'] != null) {
//       try {
//         specialDiscountAmount = double.parse(
//           order.specialDiscount!['special_discount'].toString(),
//         );
//         print(
//           'DEBUG: Order Screen - Special discount: ₹$specialDiscountAmount',
//         );
//       } catch (e) {
//         print('DEBUG: Order Screen - Error parsing special discount: $e');
//         specialDiscountAmount = 0.0;
//       }
//     }
//
//     // Check if order has promotional items for tax calculation
//     final hasPromotionalItems =
//         order.products?.any(
//           (item) => item.promoId != null && item.promoId!.isNotEmpty,
//         ) ??
//         false;
//
//     print('DEBUG: Order Screen - Has promotional items: $hasPromotionalItems');
//     print('DEBUG: Order Screen - Final subtotal: ₹$subTotal');
//
//     double sgst = 0.0;
//     double gst = 0.0;
//     if (order.taxSetting != null) {
//       for (var element in order.taxSetting!) {
//         try {
//           if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
//             // Calculate SGST on subtotal (which includes promotional prices)
//             sgst = Constant.calculateTax(
//               amount: subTotal.toString(),
//               taxModel: element,
//             );
//             print('DEBUG: Order Screen - SGST (5%) on item total: ₹$sgst');
//           } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
//             // Calculate GST on delivery charge
//             gst = Constant.calculateTax(
//               amount: double.parse(order.deliveryCharge.toString()).toString(),
//               taxModel: element,
//             );
//             print('DEBUG: Order Screen - GST (18%) on delivery fee: ₹$gst');
//           }
//         } catch (e) {
//           print('DEBUG: Order Screen - Error processing tax element: $e');
//         }
//       }
//     }
//     taxAmount = sgst + gst;
//     print('DEBUG: Order Screen - Total tax: ₹$taxAmount');
//
//     try {
//       totalAmount =
//           (subTotal - (order.discount ?? 0.0) - specialDiscountAmount) +
//           taxAmount +
//           (double.tryParse(order.deliveryCharge?.toString() ?? '0.0') ?? 0.0) +
//           (double.tryParse(order.tipAmount?.toString() ?? '0.0') ?? 0.0);
//     } catch (e) {
//       print('DEBUG: Order Screen - Error in final calculation: $e');
//       totalAmount = subTotal + taxAmount;
//     }
//
//     print('DEBUG: Order Screen - Final calculation:');
//     print('DEBUG: Order Screen - Subtotal: ₹$subTotal');
//     print('DEBUG: Order Screen - Discount: -₹${order.discount ?? 0.0}');
//     print('DEBUG: Order Screen - Special discount: -₹$specialDiscountAmount');
//     print('DEBUG: Order Screen - Tax: +₹$taxAmount');
//     print('DEBUG: Order Screen - Delivery: +₹${order.deliveryCharge ?? '0.0'}');
//     print('DEBUG: Order Screen - Tips: +₹${order.tipAmount ?? '0.0'}');
//     print('DEBUG: Order Screen - Total amount: ₹$totalAmount');
//
//     return totalAmount;
//   }
// }
//
// // Helper function to calculate the 'To Pay' value for an order
// // double calculateOrderTotal(OrderModel order) {
// //   double subTotal = 0.0;
// //   double specialDiscountAmount = 0.0;
// //   double taxAmount = 0.0;
// //   double totalAmount = 0.0;
// //
// //   if (order.products != null) {
// //     for (var element in order.products!) {
// //       if (double.parse(element.discountPrice.toString()) <= 0) {
// //         subTotal = subTotal +
// //             double.parse(element.price.toString()) * double.parse(element.quantity.toString()) +
// //             (double.parse(element.extrasPrice.toString()) * double.parse(element.quantity.toString()));
// //       } else {
// //         subTotal = subTotal +
// //             double.parse(element.discountPrice.toString()) * double.parse(element.quantity.toString()) +
// //             (double.parse(element.extrasPrice.toString()) * double.parse(element.quantity.toString()));
// //       }
// //     }
// //   }
// //
// //   if (order.specialDiscount != null && order.specialDiscount!['special_discount'] != null) {
// //     specialDiscountAmount = double.parse(order.specialDiscount!['special_discount'].toString());
// //   }
// //
// //   double sgst = 0.0;
// //   double gst = 0.0;
// //   if (order.taxSetting != null) {
// //     for (var element in order.taxSetting!) {
// //       if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
// //         sgst = Constant.calculateTax(amount: subTotal.toString(), taxModel: element);
// //       } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
// //         gst = Constant.calculateTax(amount: double.parse(order.deliveryCharge.toString()).toString(), taxModel: element);
// //       }
// //     }
// //   }
// //   taxAmount = sgst + gst;
// //
// //   totalAmount = (subTotal - double.parse(order.discount.toString()) - specialDiscountAmount) +
// //       taxAmount +
// //       double.parse(order.deliveryCharge.toString()) +
// //       double.parse(order.tipAmount.toString());
// //
// //   return totalAmount;
// // }
// // Fetch the 'ToPay' value from the 'order_Billing' collection for a given order ID
// Future<double?> fetchOrderToPay(String orderId) async {
//   try {
//     final userId = await SqlStorageConst.getFirebaseId();
//     print("fetchOrderToPay $userId");
//     print("💰 Fetching order to pay for order: $orderId");
//     final Uri uri = Uri.parse(
//       '${AppConst.baseUrl}mobile/orders/$orderId/billing/to-pay',
//     );
//     print("🌐 Making API request to: ${uri.toString()}");
//     final response = await http.get(uri, headers: await getHeaders());
//
//     if (response.statusCode == 200) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//
//       if (responseData['success'] == true) {
//         final Map<String, dynamic> data = responseData['data'];
//
//         // Check if billing record was found and has to_pay value
//         if (data['found'] == true && data['to_pay'] != null) {
//           final toPay = data['to_pay'];
//           final toPayValue = toPay is int
//               ? toPay.toDouble()
//               : double.tryParse(toPay.toString());
//
//           print("✅ Order to pay found: $toPayValue");
//           return toPayValue;
//         } else {
//           print("❌ Billing record not found or missing to_pay value");
//           return null;
//         }
//       } else {
//         print("❌ API returned error: ${responseData['message']}");
//         return null;
//       }
//     } else {
//       print("❌ HTTP error: ${response.statusCode}");
//       return null;
//     }
//   } catch (e) {
//     print("❌ Fetch order to pay failed: $e");
//     return null;
//   }
// }
//
// Future<double?> fetchOrderSergeFee(String orderId) async {
//   try {
//     final response = await http.get(
//       Uri.parse('${AppConst.baseUrl}mobile/orders/$orderId/billing/surge-fee'),
//       headers: await getHeaders(),
//     );
//
//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);
//
//       if (data['success'] == true && data['data'] != null) {
//         final billingData = data['data'];
//         return billingData['total_surge_fee']?.toDouble();
//       }
//     }
//
//     // If request fails or data not found, return null
//     return null;
//   } catch (e) {
//     // Handle any errors that occur during the API call
//     print('Error fetching surge fee: $e');
//     return null;
//   }
// }

import 'dart:async';
import 'dart:convert';

import 'package:jippymart_customer/app/auth_screen/login_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/order_details_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/my_separator.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../../../models/cart_product_model.dart';
import '../../../auth_screen/phone_number_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _isRefreshing = false;
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<DashBoardProvider, OrderProvider>(
      builder: (context, dashBoardProvider, controller, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(ImageConst.backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top,
              ),
              child: _buildContent(context, controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, OrderProvider controller) {
    if (controller.isLoading && !_isRefreshing) {
      return const OrderLoadingWidget(message: "🍽️ Loading Your Orders");
    }

    if (Constant.userModel == null) {
      return _buildLoginPrompt();
    }

    return _buildOrderList(controller);
  }

  Widget _buildLoginPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/login.gif", height: 140),
          const SizedBox(height: 12),
          Text(
            "Please Log In to Continue".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "You're not logged in. Please sign in to access your account and explore all features."
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemeData.grey500,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
          ),
          const SizedBox(height: 20),
          RoundedButtonFill(
            title: "Log in".tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () {
              Get.offAll(() => PhoneNumberScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(OrderProvider controller) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Order".tr,
                        style: TextStyle(
                          fontSize: 24,
                          color: AppThemeData.grey900,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppThemeData.primary300),
                  onPressed: () => _refreshOrders(controller),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTabBar(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildTabViews(controller)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: ShapeDecoration(
        color: AppThemeData.grey100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: AppThemeData.primary300,
        ),
        labelColor: AppThemeData.grey50,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorWeight: 0.5,
        unselectedLabelColor: AppThemeData.grey900,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          _buildTab('All'.tr),
          _buildTab('New Orders'.tr),
          _buildTab('In Progress'.tr),
          _buildTab('Delivered'.tr),
          _buildTab('Cancelled'.tr),
          _buildTab('Rejected'.tr),
        ],
      ),
    );
  }

  Widget _buildTab(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Tab(child: Text(text, style: const TextStyle(fontSize: 12))),
    );
  }

  Widget _buildTabViews(OrderProvider controller) {
    return TabBarView(
      children: [
        _buildOrderListView(
          controller.allList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.newOrderList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.inProgressList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.deliveredList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.cancelledList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.rejectedList,
          controller,
          'Order Not Found'.tr,
        ),
      ],
    );
  }

  Widget _buildOrderListView(
    List<OrderModel> orderList,
    OrderProvider controller,
    String emptyMessage,
  ) {
    if (orderList.isEmpty) {
      return Constant.showEmptyView(message: emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () => _refreshOrders(controller),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: orderList.length,
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return _buildItemView(context, orderList[index], controller);
        },
      ),
    );
  }

  Widget _buildItemView(
    BuildContext context,
    OrderModel orderModel,
    OrderProvider controller,
  ) {
    return Consumer<OrderDetailsProvider>(
      builder: (context, orderDetailsProvider, _) {
        return GestureDetector(
          onTap: () =>
              _navigateToOrderDetails(orderModel, orderDetailsProvider),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Card(
              elevation: 4,
              color: ColorConst.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildOrderHeader(orderModel, context),
                    const SizedBox(height: 10),
                    _buildOrderTotal(orderModel),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: MySeparator(color: AppThemeData.grey200),
                    ),
                    _buildOrderActions(
                      context,
                      orderModel,
                      controller,
                      orderDetailsProvider,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderHeader(OrderModel orderModel, BuildContext context) {
    return Row(
      children: [
        _buildVendorImage(orderModel, context),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  orderModel.status.toString(),
                  style: TextStyle(
                    color: Constant.statusColor(
                      status: orderModel.status.toString(),
                    ),
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                orderModel.vendor?.title?.toString() ?? "Jippy Mart",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: AppThemeData.grey900,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                orderModel.createdAt != null
                    ? Constant.timestampToDateTime(orderModel.createdAt!)
                    : "Order placed",
                style: TextStyle(
                  color: AppThemeData.grey600,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorImage(OrderModel orderModel, BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: SizedBox(
        height: Responsive.height(10, context),
        width: Responsive.width(20, context),
        child: Stack(
          children: [
            if (orderModel.vendor?.photo != null &&
                orderModel.vendor!.photo!.isNotEmpty)
              NetworkImageWidget(
                imageUrl: orderModel.vendor!.photo!,
                fit: BoxFit.cover,
                height: Responsive.height(10, context),
                width: Responsive.width(20, context),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppThemeData.grey200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.store,
                  color: AppThemeData.grey500,
                  size: Responsive.width(5, context),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.00, 1.00),
                  end: const Alignment(0, -1),
                  colors: [Colors.black.withOpacity(0), AppThemeData.grey900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotal(OrderModel orderModel) {
    return FutureBuilder<double>(
      future: calculateOrderTotalInList(orderModel),
      builder: (context, snapshot) {
        return Row(
          children: [
            Expanded(
              child: Text(
                "Total to Pay",
                style: TextStyle(
                  color: AppThemeData.grey900,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppThemeData.grey200,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else if (snapshot.hasData)
              Text(
                Constant.amountShow(amount: snapshot.data!.toString()),
                style: TextStyle(
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              )
            else
              Text(
                Constant.amountShow(
                  amount: orderModel.toPayAmount?.toString() ?? "0.0",
                ),
                style: TextStyle(
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOrderActions(
    BuildContext context,
    OrderModel orderModel,
    OrderProvider controller,
    OrderDetailsProvider orderDetailsProvider,
  ) {
    return Row(
      children: [
        if (orderModel.status == Constant.orderCompleted)
          Expanded(
            child: InkWell(
              onTap: () => _reorderItems(context, orderModel, controller),
              child: Text(
                "Reorder".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else if (orderModel.status == Constant.orderShipped ||
            orderModel.status == Constant.orderInTransit)
          Expanded(
            child: Consumer<LiveTrackingProvider>(
              builder: (context, liveTrackingProvider, _) {
                return InkWell(
                  onTap: () {
                    liveTrackingProvider.initFunction(orderModel: orderModel);
                    Get.to(const LiveTrackingScreen());
                  },
                  child: Text(
                    "Track Order".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppThemeData.primary300,
                      fontFamily: AppThemeData.semiBold,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          )
        else
          const SizedBox(),

        Expanded(
          child: InkWell(
            onTap: () =>
                _navigateToOrderDetails(orderModel, orderDetailsProvider),
            child: Text(
              "View Details".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemeData.grey900,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _reorderItems(
    BuildContext context,
    OrderModel orderModel,
    OrderProvider controller,
  ) async {
    await controller.reorderOrder(orderModel, context);
  }

  Future<void> _navigateToOrderDetails(
    OrderModel orderModel,
    OrderDetailsProvider orderDetailsProvider,
  ) async {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {});

    try {
      // Fetch surge fee in background
      final surgeFeeFuture = fetchOrderSergeFee(orderModel.id ?? '');

      orderDetailsProvider.initFunction(orderModels: orderModel);

      final surgeFee = await surgeFeeFuture;
      Get.to(() => OrderDetailsScreen(surgeFee: surgeFee));
    } catch (e) {
      ShowToastDialog.showToast("Error loading order details".tr);
    }
  }

  Future<void> _refreshOrders(OrderProvider controller) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    await controller.refreshOrders();
    _isRefreshing = false;
  }

  // Keep all your existing calculation methods

  Future<double> calculateOrderTotalInList(OrderModel order) async {
    try {
      final vendor =
          order.vendor ??
          VendorModel(
            title: "Jippy Mart",
            location: "Jippy Mart Store",
            phonenumber: "Contact Support",
            isSelfDelivery: false,
            deliveryCharge: DeliveryCharge(
              baseDeliveryCharge: 23.0,
              itemTotalThreshold: 299.0,
              freeDeliveryDistanceKm: 7.0,
              perKmChargeAboveFreeDistance: 8.0,
            ),
            latitude: 0.0,
            longitude: 0.0,
            vType: 'mart',
          );
      final deliveryCharge = vendor.deliveryCharge ?? DeliveryCharge();
      final totalDistance = order.vendor != null
          ? Constant.calculateDistance(
              vendor.latitude ?? 0.0,
              vendor.longitude ?? 0.0,
              order.address?.location?.latitude ?? 0.0,
              order.address?.location?.longitude ?? 0.0,
            )
          : 0.0;

      double subTotal = 0.0;
      double deliveryCharges = 0.0;
      double originalDeliveryFee = 0.0;
      double couponAmount = 0.0;
      double specialDiscountAmount = 0.0;
      double taxAmount = 0.0;
      double deliveryTips = double.tryParse(order.tipAmount ?? '0') ?? 0.0;

      if (order.products != null) {
        for (var element in order.products!) {
          final priceValue = double.tryParse(element.price.toString()) ?? 0.0;
          final discountPriceValue =
              double.tryParse(element.discountPrice.toString()) ?? 0.0;
          final hasPromo =
              element.promoId != null && element.promoId!.isNotEmpty;
          final isPricePromotional =
              priceValue > 0 &&
              discountPriceValue > 0 &&
              priceValue < discountPriceValue;
          final isPromotional = hasPromo || isPricePromotional;
          double itemPrice;
          if (isPromotional) {
            itemPrice = priceValue < discountPriceValue
                ? priceValue
                : discountPriceValue;
          } else if (discountPriceValue <= 0) {
            itemPrice = priceValue;
          } else {
            itemPrice = discountPriceValue;
          }
          final quantity = double.parse(element.quantity.toString());
          final extrasPrice = double.parse(element.extrasPrice.toString());
          final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
          subTotal += itemTotal;
        }
      }

      const double fallbackThreshold = 299.0;
      const double fallbackBaseCharge = 23.0;
      const double fallbackFreeKm = 5.0;
      const double fallbackPerKm = 7.0;

      final double threshold =
          (deliveryCharge.itemTotalThreshold ?? fallbackThreshold).toDouble();
      final double baseCharge =
          (deliveryCharge.baseDeliveryCharge ?? fallbackBaseCharge).toDouble();
      final double freeKm =
          (deliveryCharge.freeDeliveryDistanceKm ?? fallbackFreeKm).toDouble();
      final double perKm =
          (deliveryCharge.perKmChargeAboveFreeDistance ?? fallbackPerKm)
              .toDouble();

      final hasPromotionalItems = (order.products ?? []).any((item) {
        final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
        final discountPriceValue =
            double.tryParse(item.discountPrice.toString()) ?? 0.0;
        final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
        final isPricePromotional =
            priceValue > 0 &&
            discountPriceValue > 0 &&
            priceValue < discountPriceValue;
        return hasPromo || isPricePromotional;
      });

      if (vendor.isSelfDelivery == true &&
          Constant.isSelfDeliveryFeature == true) {
        deliveryCharges = 0.0;
        originalDeliveryFee = 0.0;
      } else if (hasPromotionalItems) {
        final promotionalItems = (order.products ?? []).where((item) {
          final priceValue = double.tryParse(item.price.toString()) ?? 0.0;
          final discountPriceValue =
              double.tryParse(item.discountPrice.toString()) ?? 0.0;
          final hasPromo = item.promoId != null && item.promoId!.isNotEmpty;
          final isPricePromotional =
              priceValue > 0 &&
              discountPriceValue > 0 &&
              priceValue < discountPriceValue;
          return hasPromo || isPricePromotional;
        }).toList();

        if (promotionalItems.isNotEmpty) {
          final firstPromoItem = promotionalItems.first;
          double promoFreeKm = 3.0;
          double promoExtraKmCharge = fallbackPerKm;
          const double promoBaseCharge = fallbackBaseCharge;

          try {
            final promoDetails =
                await FireStoreUtils.getActivePromotionForProduct(
                  productId: firstPromoItem.id ?? '',
                  restaurantId: firstPromoItem.vendorID ?? '',
                );

            if (promoDetails != null) {
              promoFreeKm =
                  (promoDetails['free_delivery_km'] as num?)?.toDouble() ??
                  promoFreeKm;
              promoExtraKmCharge =
                  (promoDetails['extra_km_charge'] as num?)?.toDouble() ??
                  promoExtraKmCharge;
            }
          } catch (_) {}

          if (totalDistance <= promoFreeKm) {
            deliveryCharges = 0.0;
            originalDeliveryFee = promoBaseCharge;
          } else {
            double extraKm = (totalDistance - promoFreeKm).ceilToDouble();
            deliveryCharges = extraKm * promoExtraKmCharge;
            originalDeliveryFee = deliveryCharges;
          }
        }
      }

      if (deliveryCharges == 0.0 && originalDeliveryFee == 0.0) {
        if (subTotal < threshold) {
          if (totalDistance <= freeKm) {
            deliveryCharges = baseCharge;
            originalDeliveryFee = baseCharge;
          } else {
            double extraKm = (totalDistance - freeKm).ceilToDouble();
            deliveryCharges = baseCharge + (extraKm * perKm);
            originalDeliveryFee = deliveryCharges;
          }
        } else {
          if (totalDistance <= freeKm) {
            deliveryCharges = 0.0;
            originalDeliveryFee = baseCharge;
          } else {
            double extraKm = (totalDistance - freeKm).ceilToDouble();
            deliveryCharges = extraKm * perKm;
            originalDeliveryFee = baseCharge + deliveryCharges;
          }
        }
      }

      if (hasPromotionalItems) {
        couponAmount = 0.0;
      } else if (order.couponId != null &&
          order.couponId!.isNotEmpty &&
          order.discount != null) {
        couponAmount = double.tryParse(order.discount.toString()) ?? 0.0;
      } else {
        couponAmount = 0.0;
      }

      if (order.specialDiscount != null &&
          order.specialDiscount!['special_discount'] != null) {
        specialDiscountAmount =
            double.tryParse(
              order.specialDiscount!['special_discount'].toString(),
            ) ??
            0.0;
      }

      final double taxableDeliveryFee = originalDeliveryFee > 0
          ? originalDeliveryFee
          : (deliveryCharges > 0 ? deliveryCharges : 0.0);

      double sgst = subTotal * 0.05;
      double gst = taxableDeliveryFee * 0.18;
      sgst = sgst.isNaN ? 0.0 : sgst;
      gst = gst.isNaN ? 0.0 : gst;
      taxAmount = sgst + gst;

      if (taxAmount == 0.0) {
        double sgstFallback = subTotal * 0.05;
        double gstFallback = taxableDeliveryFee > 0
            ? taxableDeliveryFee * 0.18
            : 0.0;
        taxAmount = sgstFallback + gstFallback;
      }
      if (taxAmount.isNaN) taxAmount = 0.0;

      bool isFreeDelivery = false;
      if (hasPromotionalItems) {
        if (deliveryCharges == 0.0 && originalDeliveryFee > 0.0) {
          isFreeDelivery = true;
        }
      } else {
        if (subTotal >= threshold && totalDistance <= freeKm) {
          isFreeDelivery = true;
        }
      }

      final totalAmount =
          (subTotal - couponAmount - specialDiscountAmount) +
          taxAmount +
          (isFreeDelivery ? 0.0 : deliveryCharges) +
          deliveryTips;

      return totalAmount;
    } catch (e) {
      print('Error calculating order total: $e');
      return order.toPayAmount?.toDouble() ?? 0.0;
    }
  }

  Future<double?> fetchOrderSergeFee(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}mobile/orders/$orderId/billing/surge-fee',
        ),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final billingData = data['data'];
          return billingData['total_surge_fee']?.toDouble();
        }
      }

      return null;
    } catch (e) {
      print('Error fetching surge fee: $e');
      return null;
    }
  }
}
