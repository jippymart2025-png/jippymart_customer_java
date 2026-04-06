// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
// import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../widgets/app_loading_widget.dart';
//
// class BestRestaurantsSection extends StatelessWidget {
//   final List restaurantList;
//
//   const BestRestaurantsSection({super.key, required this.restaurantList});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer3<
//       BestRestaurantProvider,
//       RestaurantListProvider,
//       RestaurantDetailsProvider
//     >(
//       builder:
//           (
//             context,
//             provider,
//             restaurantListProvider,
//             restaurantDetailsProvider,
//             _,
//           ) {
//             final filteredRestaurantList = provider.filteredRestaurantList;
//             final displayList = provider.displayList;
//
//             if (provider.isLoading && displayList.isEmpty) {
//               return const RestaurantLoadingWidget();
//             }
//             final allRestaurantsList = filteredRestaurantList;
//
//             if (displayList.isEmpty) {
//               return const SizedBox.shrink();
//             }
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           "Best Restaurants",
//                           style: TextStyle(
//                             fontFamily: AppThemeData.medium,
//                             color: AppThemeData.grey900,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       InkWell(
//                         onTap: () {
//                           restaurantListProvider.initFunction(
//                             vendorLists: allRestaurantsList,
//                             titles: "Best Restaurants",
//                           );
//                           Get.to(const RestaurantListScreen());
//                         },
//                         child: Text(
//                           "See all".tr,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontFamily: AppThemeData.medium,
//                             color: AppThemeData.primary300,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   // Card height: roughly screen_width/3 * (1/0.65) + paddings
//                   // Use a fixed height that matches childAspectRatio: 0.65 for a card width of ~(screenWidth - 32 - 12) / 3
//                   height:
//                       (MediaQuery.of(context).size.width - 32 - 12) / 3 / 0.65,
//                   child: ListView.separated(
//                     scrollDirection: Axis.horizontal,
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: displayList.length,
//                     separatorBuilder: (_, __) => const SizedBox(width: 6),
//                     itemBuilder: (BuildContext context, int index) {
//                       final vendorModel = displayList[index];
//                       final isClosed = !RestaurantStatusUtils.canAcceptOrders(
//                         vendorModel,
//                       );
//
//                       // Each card width matches the original grid column width
//                       final cardWidth =
//                           (MediaQuery.of(context).size.width - 32 - 12) / 3;
//
//                       return RepaintBoundary(
//                         child: SizedBox(
//                           width: cardWidth,
//                           child: InkWell(
//                             onTap: isClosed
//                                 ? null
//                                 : () {
//                                     restaurantDetailsProvider.initFunction(
//                                       vendorModels: vendorModel,
//                                     );
//                                     Get.to(const RestaurantDetailsScreen());
//                                   },
//                             borderRadius: BorderRadius.circular(16),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: AppThemeData.grey50,
//                                 borderRadius: BorderRadius.circular(16),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.05),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: Stack(
//                                 children: [
//                                   // Main Content
//                                   Padding(
//                                     padding: const EdgeInsets.all(8),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         // 🖼 Image Section
//                                         AspectRatio(
//                                           aspectRatio: 1,
//                                           child: Container(
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                               color: AppThemeData.grey200
//                                                   .withOpacity(0.5),
//                                             ),
//                                             child: Stack(
//                                               children: [
//                                                 // Restaurant Image
//                                                 ClipRRect(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                   child:
//                                                       RestaurantImageWithStatus(
//                                                         vendorModel:
//                                                             vendorModel,
//                                                         height: double.infinity,
//                                                         width: double.infinity,
//                                                       ),
//                                                 ),
//                                                 // Status Badge
//                                                 Positioned(
//                                                   top: 6,
//                                                   left: 6,
//                                                   child:
//                                                       _buildEnhancedStatusBadge(
//                                                         vendorModel,
//                                                       ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 10),
//                                         Text(
//                                           vendorModel.title ?? 'Restaurant',
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             fontFamily: AppThemeData.semiBold,
//                                             color: AppThemeData.grey900,
//                                             height: 1.2,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         const SizedBox(height: 2),
//                                         _buildDeliveryTimeAndFastRow(
//                                           vendorModel,
//                                         ),
//                                         const SizedBox(height: 1),
//                                         _buildBottomInfoRow(vendorModel),
//                                       ],
//                                     ),
//                                   ),
//                                   if (isClosed) ...[
//                                     Positioned.fill(
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           color: Colors.black.withOpacity(0.4),
//                                           borderRadius: BorderRadius.circular(
//                                             16,
//                                           ),
//                                         ),
//                                         child: Center(
//                                           child: Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 8,
//                                               vertical: 4,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: Colors.black.withOpacity(
//                                                 0.7,
//                                               ),
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                             child: Text(
//                                               'CLOSED',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 10,
//                                                 fontFamily: AppThemeData.bold,
//                                                 letterSpacing: 0.5,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//     );
//   }
//
//   Widget _buildEnhancedStatusBadge(VendorModel vendorModel) {
//     final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(
//         color: isOpen
//             ? Colors.green.withOpacity(0.9)
//             : Colors.red.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(6),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isOpen ? Icons.circle : Icons.circle_outlined,
//             size: 6,
//             color: Colors.white,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             isOpen ? 'OPEN' : 'CLOSED',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 8,
//               fontFamily: AppThemeData.bold,
//               height: 1,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDeliveryTimeAndFastRow(VendorModel vendorModel) {
//     final deliveryTime = Constant.getDeliveryTimeText(vendorModel);
//     return SizedBox(
//       height: 12,
//       child: _TimeThenFastDeliveryWidget(deliveryTime: deliveryTime),
//     );
//   }
//
//   Widget _buildBottomInfoRow(VendorModel vendorModel) {
//     // Prefer precomputed/API distance when available; fall back to live calculation
//     String distanceText;
//     if (vendorModel.distance != null && vendorModel.distance! > 0) {
//       distanceText =
//           '${vendorModel.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
//     } else {
//       distanceText =
//           '${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}';
//     }
//
//     return Row(
//       children: [
//         Expanded(
//           child: Row(
//             children: [
//               Icon(Icons.star, size: 12, color: AppThemeData.primary300),
//               const SizedBox(width: 1),
//               Expanded(
//                 child: Text(
//                   "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())}",
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontFamily: AppThemeData.medium,
//                     color: AppThemeData.grey500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 4),
//         Expanded(
//           child: Row(
//             children: [
//               Icon(
//                 Icons.location_on_outlined,
//                 size: 10,
//                 color: AppThemeData.grey400,
//               ),
//               const SizedBox(width: 2),
//               Expanded(
//                 child: Text(
//                   distanceText,
//                   style: TextStyle(
//                     fontSize: 9,
//                     fontFamily: AppThemeData.medium,
//                     color: AppThemeData.grey500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// /// First shows delivery time; after 2 seconds replaces with "Fast delivery" in the same place (looping).
// class _TimeThenFastDeliveryWidget extends StatefulWidget {
//   final String deliveryTime;
//
//   const _TimeThenFastDeliveryWidget({required this.deliveryTime});
//
//   @override
//   State<_TimeThenFastDeliveryWidget> createState() =>
//       _TimeThenFastDeliveryWidgetState();
// }
//
// class _TimeThenFastDeliveryWidgetState
//     extends State<_TimeThenFastDeliveryWidget> {
//   bool _showFastDelivery = false;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 4), (_) {
//       if (mounted) {
//         setState(() => _showFastDelivery = !_showFastDelivery);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 400),
//         switchInCurve: Curves.easeIn,
//         switchOutCurve: Curves.easeOut,
//         transitionBuilder: (Widget child, Animation<double> animation) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//         child: _showFastDelivery
//             ? Row(
//                 key: const ValueKey('fast'),
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.delivery_dining,
//                     size: 10,
//                     color: AppThemeData.primary300,
//                   ),
//                   const SizedBox(width: 2),
//                   Text(
//                     'Fast delivery',
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontFamily: AppThemeData.medium,
//                       color: AppThemeData.primary300,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               )
//             : Text(
//                 key: const ValueKey('time'),
//                 widget.deliveryTime,
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontFamily: AppThemeData.medium,
//                   color: AppThemeData.primary300,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
// import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../widgets/app_loading_widget.dart';
//
// class BestRestaurantsSection extends StatelessWidget {
//   final List<VendorModel> restaurantList;
//
//   const BestRestaurantsSection({super.key, required this.restaurantList});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer3<
//       BestRestaurantProvider,
//       RestaurantListProvider,
//       RestaurantDetailsProvider
//     >(
//       builder:
//           (
//             context,
//             provider,
//             restaurantListProvider,
//             restaurantDetailsProvider,
//             _,
//           ) {
//             final filteredRestaurantList = provider.filteredRestaurantList;
//             final displayList = provider.displayList;
//
//             if (provider.isLoading && displayList.isEmpty) {
//               return const RestaurantLoadingWidget();
//             }
//
//             if (displayList.isEmpty) return const SizedBox.shrink();
//
//             // Split into two rows for dual carousel
//             final int midPoint = (displayList.length / 2).ceil();
//             final List<VendorModel> firstRowItems = displayList
//                 .take(midPoint)
//                 .cast<VendorModel>()
//                 .toList();
//             final List<VendorModel> secondRowItems = displayList
//                 .skip(midPoint)
//                 .cast<VendorModel>()
//                 .toList();
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Swiggy/Zomato Style Header
//                 _buildHeader(
//                   context,
//                   filteredRestaurantList,
//                   restaurantListProvider,
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Dual Row Carousel
//                 _DualRowCarousel(
//                   firstRowItems: firstRowItems,
//                   secondRowItems: secondRowItems,
//                   onRestaurantTap: (vendorModel) {
//                     restaurantDetailsProvider.initFunction(
//                       vendorModels: vendorModel,
//                     );
//                     Get.to(const RestaurantDetailsScreen());
//                   },
//                 ),
//               ],
//             );
//           },
//     );
//   }
//
//   Widget _buildHeader(
//     BuildContext context,
//     List<VendorModel> filteredRestaurantList,
//     RestaurantListProvider provider,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Best Restaurants",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: AppThemeData.bold,
//                   color: AppThemeData.grey900,
//                   letterSpacing: -0.3,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "${filteredRestaurantList.length}+ restaurants near you",
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontFamily: AppThemeData.medium,
//                   color: AppThemeData.grey500,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(
//                 color: AppThemeData.primary300.withOpacity(0.3),
//               ),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () {
//                   provider.initFunction(
//                     vendorLists: filteredRestaurantList,
//                     titles: "Best Restaurants",
//                   );
//                   Get.to(const RestaurantListScreen());
//                 },
//                 borderRadius: BorderRadius.circular(20),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         "See all",
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: AppThemeData.medium,
//                           color: AppThemeData.primary300,
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Icon(
//                         Icons.arrow_forward_rounded,
//                         size: 14,
//                         color: AppThemeData.primary300,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  DUAL ROW CAROUSEL (Swiggy/Zomato Style)
// // ─────────────────────────────────────────────────────────────
//
// class _DualRowCarousel extends StatelessWidget {
//   final List<VendorModel> firstRowItems;
//   final List<VendorModel> secondRowItems;
//   final Function(VendorModel) onRestaurantTap;
//
//   const _DualRowCarousel({
//     required this.firstRowItems,
//     required this.secondRowItems,
//     required this.onRestaurantTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final cardWidth = (screenWidth - 48) / 2.2; // Shows 2.2 cards
//     final cardHeight = cardWidth / 0.75;
//
//     return Column(
//       children: [
//         // First Row Carousel
//         _SmoothCarousel(
//           items: firstRowItems,
//           cardWidth: cardWidth,
//           cardHeight: cardHeight,
//           onTap: onRestaurantTap,
//         ),
//         const SizedBox(height: 20),
//
//         // Second Row Carousel
//         _SmoothCarousel(
//           items: secondRowItems,
//           cardWidth: cardWidth,
//           cardHeight: cardHeight,
//           onTap: onRestaurantTap,
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  SMOOTH CAROUSEL (Manual Scroll Only - No Auto Slide)
// // ─────────────────────────────────────────────────────────────
//
// class _SmoothCarousel extends StatelessWidget {
//   final List<VendorModel> items;
//   final double cardWidth;
//   final double cardHeight;
//   final Function(VendorModel) onTap;
//
//   const _SmoothCarousel({
//     required this.items,
//     required this.cardWidth,
//     required this.cardHeight,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (items.isEmpty) return const SizedBox.shrink();
//
//     return SizedBox(
//       height: cardHeight + 20,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         itemCount: items.length,
//         itemBuilder: (context, index) {
//           final vendorModel = items[index];
//           final bool isClosed = !RestaurantStatusUtils.canAcceptOrders(
//             vendorModel,
//           );
//
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: _ModernRestaurantCard(
//               vendorModel: vendorModel,
//               isClosed: isClosed,
//               cardWidth: cardWidth,
//               cardHeight: cardHeight,
//               onTap: () => onTap(vendorModel),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  MODERN RESTAURANT CARD (Swiggy/Zomato Inspired)
// // ─────────────────────────────────────────────────────────────
//
// class _ModernRestaurantCard extends StatefulWidget {
//   final VendorModel vendorModel;
//   final bool isClosed;
//   final double cardWidth;
//   final double cardHeight;
//   final VoidCallback onTap;
//
//   const _ModernRestaurantCard({
//     required this.vendorModel,
//     required this.isClosed,
//     required this.cardWidth,
//     required this.cardHeight,
//     required this.onTap,
//   });
//
//   @override
//   State<_ModernRestaurantCard> createState() => _ModernRestaurantCardState();
// }
//
// class _ModernRestaurantCardState extends State<_ModernRestaurantCard>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _scaleCtrl;
//
//   @override
//   void initState() {
//     super.initState();
//     _scaleCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 120),
//       lowerBound: 0.96,
//       upperBound: 1.0,
//       value: 1.0,
//     );
//   }
//
//   @override
//   void dispose() {
//     _scaleCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final v = widget.vendorModel;
//     final rating = Constant.calculateReview(
//       reviewCount: v.reviewsCount.toString(),
//       reviewSum: v.reviewsSum.toString(),
//     );
//     final distanceText = _getDistanceText(v);
//
//     // Get random offer label for demo
//     final offerLabel = _getRandomOfferLabel();
//
//     return GestureDetector(
//       onTapDown: widget.isClosed ? null : (_) => _scaleCtrl.reverse(),
//       onTapUp: widget.isClosed
//           ? null
//           : (_) {
//               _scaleCtrl.forward();
//               widget.onTap();
//             },
//       onTapCancel: widget.isClosed ? null : () => _scaleCtrl.forward(),
//       child: ScaleTransition(
//         scale: _scaleCtrl,
//         child: SizedBox(
//           width: widget.cardWidth,
//           height: widget.cardHeight,
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Image Container with Badges
//                 Stack(
//                   children: [
//                     ClipRRect(
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(16),
//                         topRight: Radius.circular(16),
//                       ),
//                       child: SizedBox(
//                         width: double.infinity,
//                         height: widget.cardWidth * 0.85,
//                         child: RestaurantImageWithStatus(
//                           vendorModel: v,
//                           height: double.infinity,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//
//                     // Promo Badge (Swiggy/Zomato Style)
//                     Positioned(
//                       left: 8,
//                       bottom: 8,
//                       child: _PromoBadge(label: offerLabel),
//                     ),
//
//                     // Rating Badge
//                     Positioned(
//                       top: 8,
//                       left: 8,
//                       child: _RatingBadge(rating: rating),
//                     ),
//                   ],
//                 ),
//
//                 // Restaurant Info
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(16),
//                         bottomRight: Radius.circular(16),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Restaurant Name
//                             Text(
//                               v.title ?? 'Restaurant',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.black87,
//                                 height: 1.2,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//
//                             // Cuisine Type / Category
//                             // Text(
//                             //   v.category ?? v.type ?? 'Restaurant',
//                             //   style: TextStyle(
//                             //     fontSize: 10,
//                             //     color: Colors.grey[600],
//                             //     height: 1.2,
//                             //   ),
//                             //   maxLines: 1,
//                             //   overflow: TextOverflow.ellipsis,
//                             // ),
//                             const SizedBox(height: 4),
//
//                             // Delivery Info Row
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.access_time_filled,
//                                   size: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   Constant.getDeliveryTimeText(v),
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.grey[600],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Icon(
//                                   Icons.location_on,
//                                   size: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Expanded(
//                                   child: Text(
//                                     distanceText,
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       color: Colors.grey[600],
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//
//                         // Status Badge
//                         if (widget.isClosed)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.red.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: const Text(
//                               'Temporarily Closed',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.red,
//                               ),
//                             ),
//                           )
//                         else
//                           _FastDeliveryToggle(
//                             deliveryTime: Constant.getDeliveryTimeText(v),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _getDistanceText(VendorModel v) {
//     if (v.distance != null && v.distance! > 0) {
//       return '${v.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
//     }
//     return '${Constant.getDistanceFromVendor(v)} ${Constant.distanceType}';
//   }
//
//   String _getRandomOfferLabel() {
//     final random = Random();
//     final offers = [
//       "FLAT 65% OFF",
//       "FLAT 50% OFF",
//       "FLAT 40% OFF",
//       "UP TO 60% OFF",
//       "₹100 OFF",
//       "₹150 OFF",
//       "₹200 OFF",
//       "BUY 1 GET 1",
//     ];
//     return offers[random.nextInt(offers.length)];
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  PROMO BADGE
// // ─────────────────────────────────────────────────────────────
//
// class _PromoBadge extends StatelessWidget {
//   final String label;
//
//   const _PromoBadge({required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     Color getColor() {
//       if (label.contains("Best Seller") || label.contains("Top Rated")) {
//         return Colors.amber.shade700;
//       }
//       if (label.contains("Hot Deal") || label.contains("Limited")) {
//         return Colors.red.shade600;
//       }
//       if (label.contains("Trending") || label.contains("Popular")) {
//         return Colors.purple.shade600;
//       }
//       return Colors.transparent;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [getColor(), getColor().withOpacity(0.8)],
//         ),
//         borderRadius: BorderRadius.circular(6),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             label.contains("Best")
//                 ? Icons.emoji_events
//                 : label.contains("Hot")
//                 ? Icons.local_fire_department
//                 : label.contains("Trending")
//                 ? Icons.trending_up
//                 : Icons.local_offer,
//             size: 10,
//             color: Colors.white,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 9,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 0.3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  RATING BADGE
// // ─────────────────────────────────────────────────────────────
//
// class _RatingBadge extends StatelessWidget {
//   final dynamic rating;
//
//   const _RatingBadge({required this.rating});
//
//   @override
//   Widget build(BuildContext context) {
//     final random = Random();
//
//     // random rating between 4.0 and 5.0
//     double ratingValue = 4.0 + random.nextDouble();
//     Color ratingColor = ratingValue >= 4.0
//         ? Colors.green
//         : ratingValue >= 3.0
//         ? Colors.orange
//         : Colors.red;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.75),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.star, size: 10, color: ratingColor),
//           const SizedBox(width: 2),
//           Text(
//             ratingValue.toStringAsFixed(1),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  FAST DELIVERY TOGGLE (Animated)
// // ─────────────────────────────────────────────────────────────
//
// class _FastDeliveryToggle extends StatefulWidget {
//   final String deliveryTime;
//
//   const _FastDeliveryToggle({required this.deliveryTime});
//
//   @override
//   State<_FastDeliveryToggle> createState() => _FastDeliveryToggleState();
// }
//
// class _FastDeliveryToggleState extends State<_FastDeliveryToggle> {
//   bool _showFastDelivery = false;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (mounted) setState(() => _showFastDelivery = !_showFastDelivery);
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 500),
//       switchInCurve: Curves.easeInOut,
//       switchOutCurve: Curves.easeInOut,
//       transitionBuilder: (child, animation) {
//         return FadeTransition(
//           opacity: animation,
//           child: SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, 0.2),
//               end: Offset.zero,
//             ).animate(animation),
//             child: child,
//           ),
//         );
//       },
//       child: _showFastDelivery
//           ? Container(
//               key: const ValueKey('fast'),
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.flash_on, size: 12, color: Colors.green[700]),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Fast Delivery',
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.green[700],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : Container(
//               key: const ValueKey('time'),
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.access_time, size: 12, color: Colors.orange[700]),
//                   const SizedBox(width: 4),
//                   Text(
//                     widget.deliveryTime,
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.orange[700],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
// import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../widgets/app_loading_widget.dart';
//
// class BestRestaurantsSection extends StatelessWidget {
//   final List<VendorModel> restaurantList;
//
//   const BestRestaurantsSection({super.key, required this.restaurantList});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer3<
//       BestRestaurantProvider,
//       RestaurantListProvider,
//       RestaurantDetailsProvider
//     >(
//       builder:
//           (
//             context,
//             provider,
//             restaurantListProvider,
//             restaurantDetailsProvider,
//             _,
//           ) {
//             final filteredRestaurantList = provider.filteredRestaurantList;
//             final displayList = provider.displayList;
//
//             if (provider.isLoading && displayList.isEmpty) {
//               return const RestaurantLoadingWidget();
//             }
//
//             if (displayList.isEmpty) return const SizedBox.shrink();
//
//             final int midPoint = (displayList.length / 2).ceil();
//             final List<VendorModel> firstRowItems = displayList
//                 .take(midPoint)
//                 .cast<VendorModel>()
//                 .toList();
//             final List<VendorModel> secondRowItems = displayList
//                 .skip(midPoint)
//                 .cast<VendorModel>()
//                 .toList();
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(
//                   context,
//                   filteredRestaurantList,
//                   restaurantListProvider,
//                 ),
//                 const SizedBox(height: 16),
//                 _DualRowCarousel(
//                   firstRowItems: firstRowItems,
//                   secondRowItems: secondRowItems,
//                   onRestaurantTap: (vendorModel) {
//                     restaurantDetailsProvider.initFunction(
//                       vendorModels: vendorModel,
//                     );
//                     Get.to(const RestaurantDetailsScreen());
//                   },
//                 ),
//               ],
//             );
//           },
//     );
//   }
//
//   Widget _buildHeader(
//     BuildContext context,
//     List<VendorModel> filteredRestaurantList,
//     RestaurantListProvider provider,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Best Restaurants",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: AppThemeData.bold,
//                   color: AppThemeData.grey900,
//                   letterSpacing: -0.3,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 "${filteredRestaurantList.length}+ restaurants near you",
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontFamily: AppThemeData.medium,
//                   color: AppThemeData.grey500,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(
//                 color: AppThemeData.primary300.withOpacity(0.3),
//               ),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () {
//                   provider.initFunction(
//                     vendorLists: filteredRestaurantList,
//                     titles: "Best Restaurants",
//                   );
//                   Get.to(const RestaurantListScreen());
//                 },
//                 borderRadius: BorderRadius.circular(20),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         "See all",
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: AppThemeData.medium,
//                           color: AppThemeData.primary300,
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Icon(
//                         Icons.arrow_forward_rounded,
//                         size: 14,
//                         color: AppThemeData.primary300,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  DUAL ROW CAROUSEL — same-direction linked scroll
// // ─────────────────────────────────────────────────────────────
//
// class _DualRowCarousel extends StatefulWidget {
//   final List<VendorModel> firstRowItems;
//   final List<VendorModel> secondRowItems;
//   final Function(VendorModel) onRestaurantTap;
//
//   const _DualRowCarousel({
//     required this.firstRowItems,
//     required this.secondRowItems,
//     required this.onRestaurantTap,
//   });
//
//   @override
//   State<_DualRowCarousel> createState() => _DualRowCarouselState();
// }
//
// class _DualRowCarouselState extends State<_DualRowCarousel> {
//   final ScrollController _row1Controller = ScrollController();
//   final ScrollController _row2Controller = ScrollController();
//
//   bool _syncing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _row1Controller.addListener(_onRow1Scroll);
//     _row2Controller.addListener(_onRow2Scroll);
//   }
//
//   void _onRow1Scroll() {
//     if (_syncing) return;
//     if (!_row2Controller.hasClients || !_row1Controller.hasClients) return;
//
//     final double max1 = _row1Controller.position.maxScrollExtent;
//     final double max2 = _row2Controller.position.maxScrollExtent;
//     if (max1 <= 0 || max2 <= 0) return;
//
//     _syncing = true;
//     final double ratio = _row1Controller.offset / max1;
//     _row2Controller.jumpTo((max2 * ratio).clamp(0.0, max2));
//     _syncing = false;
//   }
//
//   void _onRow2Scroll() {
//     if (_syncing) return;
//     if (!_row1Controller.hasClients || !_row2Controller.hasClients) return;
//
//     final double max2 = _row2Controller.position.maxScrollExtent;
//     final double max1 = _row1Controller.position.maxScrollExtent;
//     if (max2 <= 0 || max1 <= 0) return;
//
//     _syncing = true;
//     final double ratio = _row2Controller.offset / max2;
//     _row1Controller.jumpTo((max1 * ratio).clamp(0.0, max1));
//     _syncing = false;
//   }
//
//   @override
//   void dispose() {
//     _row1Controller.dispose();
//     _row2Controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final cardWidth = (screenWidth - 48) / 2.2;
//     final cardHeight = cardWidth / 0.75;
//
//     return Column(
//       children: [
//         _SmoothCarousel(
//           items: widget.firstRowItems,
//           controller: _row1Controller,
//           cardWidth: cardWidth,
//           cardHeight: cardHeight,
//           onTap: widget.onRestaurantTap,
//         ),
//         const SizedBox(height: 20),
//         _SmoothCarousel(
//           items: widget.secondRowItems,
//           controller: _row2Controller,
//           cardWidth: cardWidth,
//           cardHeight: cardHeight,
//           onTap: widget.onRestaurantTap,
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  SMOOTH CAROUSEL ROW
// // ─────────────────────────────────────────────────────────────
//
// class _SmoothCarousel extends StatelessWidget {
//   final List<VendorModel> items;
//   final ScrollController controller;
//   final double cardWidth;
//   final double cardHeight;
//   final Function(VendorModel) onTap;
//
//   const _SmoothCarousel({
//     required this.items,
//     required this.controller,
//     required this.cardWidth,
//     required this.cardHeight,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (items.isEmpty) return const SizedBox.shrink();
//
//     return SizedBox(
//       height: cardHeight + 20,
//       child: ListView.builder(
//         controller: controller,
//         scrollDirection: Axis.horizontal,
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         itemCount: items.length,
//         itemBuilder: (context, index) {
//           final vendorModel = items[index];
//           final bool isClosed = !RestaurantStatusUtils.canAcceptOrders(
//             vendorModel,
//           );
//
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: _ModernRestaurantCard(
//               vendorModel: vendorModel,
//               isClosed: isClosed,
//               cardWidth: cardWidth,
//               cardHeight: cardHeight,
//               onTap: () => onTap(vendorModel),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  MODERN RESTAURANT CARD — UI unchanged
// // ─────────────────────────────────────────────────────────────
//
// class _ModernRestaurantCard extends StatefulWidget {
//   final VendorModel vendorModel;
//   final bool isClosed;
//   final double cardWidth;
//   final double cardHeight;
//   final VoidCallback onTap;
//
//   const _ModernRestaurantCard({
//     required this.vendorModel,
//     required this.isClosed,
//     required this.cardWidth,
//     required this.cardHeight,
//     required this.onTap,
//   });
//
//   @override
//   State<_ModernRestaurantCard> createState() => _ModernRestaurantCardState();
// }
//
// class _ModernRestaurantCardState extends State<_ModernRestaurantCard>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _scaleCtrl;
//
//   @override
//   void initState() {
//     super.initState();
//     _scaleCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 120),
//       lowerBound: 0.96,
//       upperBound: 1.0,
//       value: 1.0,
//     );
//   }
//
//   @override
//   void dispose() {
//     _scaleCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final v = widget.vendorModel;
//     final rating = Constant.calculateReview(
//       reviewCount: v.reviewsCount.toString(),
//       reviewSum: v.reviewsSum.toString(),
//     );
//     final distanceText = _getDistanceText(v);
//     final offerLabel = _getRandomOfferLabel();
//
//     return GestureDetector(
//       onTapDown: widget.isClosed ? null : (_) => _scaleCtrl.reverse(),
//       onTapUp: widget.isClosed
//           ? null
//           : (_) {
//               _scaleCtrl.forward();
//               widget.onTap();
//             },
//       onTapCancel: widget.isClosed ? null : () => _scaleCtrl.forward(),
//       child: ScaleTransition(
//         scale: _scaleCtrl,
//         child: SizedBox(
//           width: widget.cardWidth,
//           height: widget.cardHeight,
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Stack(
//                   children: [
//                     ClipRRect(
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(16),
//                         topRight: Radius.circular(16),
//                       ),
//                       child: SizedBox(
//                         width: double.infinity,
//                         height: widget.cardWidth * 0.85,
//                         child: RestaurantImageWithStatus(
//                           vendorModel: v,
//                           height: double.infinity,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       left: 8,
//                       bottom: 8,
//                       child: _PromoBadge(label: offerLabel),
//                     ),
//                     Positioned(
//                       top: 8,
//                       left: 8,
//                       child: _RatingBadge(rating: rating),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(16),
//                         bottomRight: Radius.circular(16),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               v.title ?? 'Restaurant',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.black87,
//                                 height: 1.2,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.access_time_filled,
//                                   size: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   Constant.getDeliveryTimeText(v),
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.grey[600],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Icon(
//                                   Icons.location_on,
//                                   size: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Expanded(
//                                   child: Text(
//                                     distanceText,
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       color: Colors.grey[600],
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         if (widget.isClosed)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.red.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: const Text(
//                               'Temporarily Closed',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.red,
//                               ),
//                             ),
//                           )
//                         else
//                           _FastDeliveryToggle(
//                             deliveryTime: Constant.getDeliveryTimeText(v),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _getDistanceText(VendorModel v) {
//     if (v.distance != null && v.distance! > 0) {
//       return '${v.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
//     }
//     return '${Constant.getDistanceFromVendor(v)} ${Constant.distanceType}';
//   }
//
//   String _getRandomOfferLabel() {
//     final random = Random();
//     final offers = [
//       "FLAT 65% OFF",
//       "FLAT 50% OFF",
//       "FLAT 40% OFF",
//       "UP TO 60% OFF",
//       "₹100 OFF",
//       "₹150 OFF",
//       "₹200 OFF",
//       "BUY 1 GET 1",
//     ];
//     return offers[random.nextInt(offers.length)];
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  PROMO BADGE
// // ─────────────────────────────────────────────────────────────
//
// class _PromoBadge extends StatelessWidget {
//   final String label;
//
//   const _PromoBadge({required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     Color getColor() {
//       if (label.contains("Best Seller") || label.contains("Top Rated")) {
//         return Colors.amber.shade700;
//       }
//       if (label.contains("Hot Deal") || label.contains("Limited")) {
//         return Colors.red.shade600;
//       }
//       if (label.contains("Trending") || label.contains("Popular")) {
//         return Colors.purple.shade600;
//       }
//       return Colors.transparent;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [getColor(), getColor().withOpacity(0.8)],
//         ),
//         borderRadius: BorderRadius.circular(6),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             label.contains("Best")
//                 ? Icons.emoji_events
//                 : label.contains("Hot")
//                 ? Icons.local_fire_department
//                 : label.contains("Trending")
//                 ? Icons.trending_up
//                 : Icons.local_offer,
//             size: 10,
//             color: Colors.white,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 9,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 0.3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  RATING BADGE
// // ─────────────────────────────────────────────────────────────
//
// class _RatingBadge extends StatelessWidget {
//   final dynamic rating;
//
//   const _RatingBadge({required this.rating});
//
//   @override
//   Widget build(BuildContext context) {
//     final random = Random();
//     double ratingValue = 4.0 + random.nextDouble();
//     Color ratingColor = ratingValue >= 4.0
//         ? Colors.green
//         : ratingValue >= 3.0
//         ? Colors.orange
//         : Colors.red;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.75),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.star, size: 10, color: ratingColor),
//           const SizedBox(width: 2),
//           Text(
//             ratingValue.toStringAsFixed(1),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  FAST DELIVERY TOGGLE (Animated)
// // ─────────────────────────────────────────────────────────────
//
// class _FastDeliveryToggle extends StatefulWidget {
//   final String deliveryTime;
//
//   const _FastDeliveryToggle({required this.deliveryTime});
//
//   @override
//   State<_FastDeliveryToggle> createState() => _FastDeliveryToggleState();
// }
//
// class _FastDeliveryToggleState extends State<_FastDeliveryToggle> {
//   bool _showFastDelivery = false;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (mounted) setState(() => _showFastDelivery = !_showFastDelivery);
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 500),
//       switchInCurve: Curves.easeInOut,
//       switchOutCurve: Curves.easeInOut,
//       transitionBuilder: (child, animation) {
//         return FadeTransition(
//           opacity: animation,
//           child: SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, 0.2),
//               end: Offset.zero,
//             ).animate(animation),
//             child: child,
//           ),
//         );
//       },
//       child: _showFastDelivery
//           ? Container(
//               key: const ValueKey('fast'),
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.flash_on, size: 12, color: Colors.green[700]),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Fast Delivery',
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.green[700],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : Container(
//               key: const ValueKey('time'),
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.access_time, size: 12, color: Colors.orange[700]),
//                   const SizedBox(width: 4),
//                   Text(
//                     widget.deliveryTime,
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.orange[700],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:provider/provider.dart';

import '../../../../../widgets/app_loading_widget.dart';

// ─────────────────────────────────────────────────────────────
//  BEST RESTAURANTS SECTION
// ─────────────────────────────────────────────────────────────

class BestRestaurantsSection extends StatelessWidget {
  final List<VendorModel> restaurantList;

  const BestRestaurantsSection({super.key, required this.restaurantList});

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      BestRestaurantProvider,
      RestaurantListProvider,
      RestaurantDetailsProvider
    >(
      builder:
          (
            context,
            provider,
            restaurantListProvider,
            restaurantDetailsProvider,
            _,
          ) {
            final filteredRestaurantList = provider.filteredRestaurantList;
            final displayList = provider.displayList;

            if (provider.isLoading && displayList.isEmpty) {
              return const RestaurantLoadingWidget();
            }

            if (displayList.isEmpty) return const SizedBox.shrink();

            final int midPoint = (displayList.length / 2).ceil();
            final List<VendorModel> firstRowItems = displayList
                .take(midPoint)
                .cast<VendorModel>()
                .toList();
            final List<VendorModel> secondRowItems = displayList
                .skip(midPoint)
                .cast<VendorModel>()
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  context,
                  filteredRestaurantList,
                  restaurantListProvider,
                ),
                const SizedBox(height: 16),
                _DualRowCarousel(
                  firstRowItems: firstRowItems,
                  secondRowItems: secondRowItems,
                  onRestaurantTap: (vendorModel) {
                    restaurantDetailsProvider.initFunction(
                      vendorModels: vendorModel,
                    );
                    Get.to(const RestaurantDetailsScreen());
                  },
                ),
              ],
            );
          },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<VendorModel> filteredRestaurantList,
    RestaurantListProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Best Restaurants",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppThemeData.bold,
                  color: AppThemeData.grey900,
                  letterSpacing: -0.3,
                ),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   "${filteredRestaurantList.length}+ restaurants near you",
              //   style: TextStyle(
              //     fontSize: 12,
              //     fontFamily: AppThemeData.medium,
              //     color: AppThemeData.grey500,
              //   ),
              // ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppThemeData.primary300.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  provider.initFunction(
                    vendorLists: filteredRestaurantList,
                    titles: "Best Restaurants",
                  );
                  Get.to(const RestaurantListScreen());
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "See all",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.primary300,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppThemeData.primary300,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DUAL ROW CAROUSEL — same-direction linked scroll
// ─────────────────────────────────────────────────────────────

class _DualRowCarousel extends StatefulWidget {
  final List<VendorModel> firstRowItems;
  final List<VendorModel> secondRowItems;
  final Function(VendorModel) onRestaurantTap;

  const _DualRowCarousel({
    required this.firstRowItems,
    required this.secondRowItems,
    required this.onRestaurantTap,
  });

  @override
  State<_DualRowCarousel> createState() => _DualRowCarouselState();
}

class _DualRowCarouselState extends State<_DualRowCarousel> {
  final ScrollController _row1Controller = ScrollController();
  final ScrollController _row2Controller = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _row1Controller.addListener(_onRow1Scroll);
    _row2Controller.addListener(_onRow2Scroll);
  }

  void _onRow1Scroll() {
    if (_syncing) return;
    if (!_row2Controller.hasClients || !_row1Controller.hasClients) return;
    final double max1 = _row1Controller.position.maxScrollExtent;
    final double max2 = _row2Controller.position.maxScrollExtent;
    if (max1 <= 0 || max2 <= 0) return;
    _syncing = true;
    _row2Controller.jumpTo(
      (max2 * (_row1Controller.offset / max1)).clamp(0.0, max2),
    );
    _syncing = false;
  }

  void _onRow2Scroll() {
    if (_syncing) return;
    if (!_row1Controller.hasClients || !_row2Controller.hasClients) return;
    final double max2 = _row2Controller.position.maxScrollExtent;
    final double max1 = _row1Controller.position.maxScrollExtent;
    if (max2 <= 0 || max1 <= 0) return;
    _syncing = true;
    _row1Controller.jumpTo(
      (max1 * (_row2Controller.offset / max2)).clamp(0.0, max1),
    );
    _syncing = false;
  }

  @override
  void dispose() {
    _row1Controller.dispose();
    _row2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2.2;
    final cardHeight = cardWidth / 0.75;

    return Column(
      children: [
        _SmoothCarousel(
          items: widget.firstRowItems,
          controller: _row1Controller,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          onTap: widget.onRestaurantTap,
        ),
        const SizedBox(height: 20),
        _SmoothCarousel(
          items: widget.secondRowItems,
          controller: _row2Controller,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          onTap: widget.onRestaurantTap,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SMOOTH CAROUSEL ROW
// ─────────────────────────────────────────────────────────────

class _SmoothCarousel extends StatelessWidget {
  final List<VendorModel> items;
  final ScrollController controller;
  final double cardWidth;
  final double cardHeight;
  final Function(VendorModel) onTap;

  const _SmoothCarousel({
    required this.items,
    required this.controller,
    required this.cardWidth,
    required this.cardHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: cardHeight + 20,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final vendorModel = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _RestaurantCard(
              vendorModel: vendorModel,
              cardWidth: cardWidth,
              cardHeight: cardHeight,
              onTap: () => onTap(vendorModel),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RESTAURANT CARD
//  - offerLabel  → v.authorName (comes from backend)
//  - rating      → computed from reviewsCount + reviewsSum (real data)
//  - isClosed    → computed once here, not inside card
// ─────────────────────────────────────────────────────────────

class _RestaurantCard extends StatefulWidget {
  final VendorModel vendorModel;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.vendorModel,
    required this.cardWidth,
    required this.cardHeight,
    required this.onTap,
  });

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  // Cached values — computed once, not on every build
  late final bool _isClosed;
  late final double _rating;
  late final String _distanceText;
  late final String _deliveryTime;
  late final String? _offerLabel;

  @override
  void initState() {
    super.initState();
    final v = widget.vendorModel;

    _isClosed = !RestaurantStatusUtils.canAcceptOrders(v);
    _rating = _parseRating(v);
    _distanceText = _buildDistanceText(v);
    _deliveryTime = Constant.getDeliveryTimeText(v);

    final raw = v.offer_lable?.trim() ?? '';
    _offerLabel = raw.isNotEmpty ? raw : null;

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────

  static double _parseRating(VendorModel v) {
    final count = int.tryParse(v.reviewsCount?.toString() ?? '0') ?? 0;
    final sum = double.tryParse(v.reviewsSum?.toString() ?? '0') ?? 0.0;
    if (count == 0) return 0.0;
    return (sum / count).clamp(0.0, 5.0);
  }

  static String _buildDistanceText(VendorModel v) {
    if (v.distance != null && v.distance! > 0) {
      return '${v.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
    }
    return '${Constant.getDistanceFromVendor(v)} ${Constant.distanceType}';
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final v = widget.vendorModel;

    return GestureDetector(
      onTapDown: _isClosed ? null : (_) => _scaleCtrl.reverse(),
      onTapUp: _isClosed
          ? null
          : (_) {
              _scaleCtrl.forward();
              widget.onTap();
            },
      onTapCancel: _isClosed ? null : () => _scaleCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: SizedBox(
          width: widget.cardWidth,
          height: widget.cardHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image + Badges ──────────────────────────
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: widget.cardWidth * 0.85,
                        child: RestaurantImageWithStatus(
                          vendorModel: v,
                          height: double.infinity,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Offer badge — only rendered if backend sent a label
                    if (_offerLabel != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _PromoBadge(label: _offerLabel!),
                      ),

                    // Rating badge — only rendered if restaurant has reviews
                    if (_rating > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _RatingBadge(rating: _rating),
                      ),
                  ],
                ),

                // ── Info ─────────────────────────────────────
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.title ?? 'Restaurant',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  size: 10,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _deliveryTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.location_on,
                                  size: 10,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _distanceText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Bottom status badge
                        if (_isClosed)
                          _ClosedBadge()
                        else
                          _DeliveryToggleBadge(deliveryTime: _deliveryTime),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROMO BADGE
//  Color is derived from the label text sent by backend.
//  Falls back to brand primary color for unknown labels.
// ─────────────────────────────────────────────────────────────

class _PromoBadge extends StatelessWidget {
  final String label;

  const _PromoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RATING BADGE — uses real computed rating, no Random()
// ─────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  Color get _starColor {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: _starColor),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CLOSED BADGE
// ─────────────────────────────────────────────────────────────

class _ClosedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Temporarily Closed',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DELIVERY TOGGLE BADGE
//  Alternates between delivery time and "Fast Delivery" every 3s.
// ─────────────────────────────────────────────────────────────

class _DeliveryToggleBadge extends StatefulWidget {
  final String deliveryTime;

  const _DeliveryToggleBadge({required this.deliveryTime});

  @override
  State<_DeliveryToggleBadge> createState() => _DeliveryToggleBadgeState();
}

class _DeliveryToggleBadgeState extends State<_DeliveryToggleBadge> {
  bool _showFastDelivery = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _showFastDelivery = !_showFastDelivery);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _showFastDelivery
          ? _badge(
              key: const ValueKey('fast'),
              icon: Icons.flash_on,
              label: 'Fast Delivery',
              color: Colors.green,
            )
          : _badge(
              key: const ValueKey('time'),
              icon: Icons.access_time,
              label: widget.deliveryTime,
              color: Colors.orange,
            ),
    );
  }

  Widget _badge({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
