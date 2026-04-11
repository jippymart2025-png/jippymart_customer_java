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
// // ─────────────────────────────────────────────────────────────
// //  BEST RESTAURANTS SECTION
// // ─────────────────────────────────────────────────────────────
//
// // const _kGradStart = Color(0xFFE8192C);
// // const _kGradEnd = Color(0xFFFF6B35);
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
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             const Color(0xFFFF4E1F),
//             const Color(0xFFFF4E1F),
//             const Color(0xFFFF4E1F),
//           ],
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // LEFT SIDE
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Best Restaurants",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: AppThemeData.bold,
//                     color: Colors.white,
//                     // 👈 IMPORTANT
//                     letterSpacing: -0.3,
//                   ),
//                 ),
//               ],
//             ),
//
//             // RIGHT SIDE BUTTON
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white.withOpacity(0.4)),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () {
//                     provider.initFunction(
//                       vendorLists: filteredRestaurantList,
//                       titles: "Best Restaurants",
//                     );
//                     Get.to(const RestaurantListScreen());
//                   },
//                   borderRadius: BorderRadius.circular(20),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     child: Row(
//                       children: [
//                         Text(
//                           "See all",
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             fontFamily: AppThemeData.medium,
//                             color: Colors.white, // 👈 IMPORTANT
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         const Icon(
//                           Icons.arrow_forward_rounded,
//                           size: 14,
//                           color: Colors.white, // 👈 IMPORTANT
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
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
//     final double max1 = _row1Controller.position.maxScrollExtent;
//     final double max2 = _row2Controller.position.maxScrollExtent;
//     if (max1 <= 0 || max2 <= 0) return;
//     _syncing = true;
//     _row2Controller.jumpTo(
//       (max2 * (_row1Controller.offset / max1)).clamp(0.0, max2),
//     );
//     _syncing = false;
//   }
//
//   void _onRow2Scroll() {
//     if (_syncing) return;
//     if (!_row1Controller.hasClients || !_row2Controller.hasClients) return;
//     final double max2 = _row2Controller.position.maxScrollExtent;
//     final double max1 = _row1Controller.position.maxScrollExtent;
//     if (max2 <= 0 || max1 <= 0) return;
//     _syncing = true;
//     _row1Controller.jumpTo(
//       (max1 * (_row2Controller.offset / max2)).clamp(0.0, max1),
//     );
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
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         // gradient: LinearGradient(
//         //   begin: Alignment.topLeft,
//         //   end: Alignment.bottomRight,
//         //   colors: [
//         //     const Color(0xFFFF4E1F),
//         //     const Color(0xFFFF4E1F),
//         //     const Color(0xFFFF4E1F),
//         //   ],
//         // ),
//       ),
//       child: Column(
//         children: [
//           _SmoothCarousel(
//             items: widget.firstRowItems,
//             controller: _row1Controller,
//             cardWidth: cardWidth,
//             cardHeight: cardHeight,
//             onTap: widget.onRestaurantTap,
//           ),
//           const SizedBox(height: 20),
//           _SmoothCarousel(
//             items: widget.secondRowItems,
//             controller: _row2Controller,
//             cardWidth: cardWidth,
//             cardHeight: cardHeight,
//             onTap: widget.onRestaurantTap,
//           ),
//         ],
//       ),
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
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: _RestaurantCard(
//               vendorModel: vendorModel,
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
// //  RESTAURANT CARD
// //  - offerLabel  → v.authorName (comes from backend)
// //  - rating      → computed from reviewsCount + reviewsSum (real data)
// //  - isClosed    → computed once here, not inside card
// // ─────────────────────────────────────────────────────────────
//
// class _RestaurantCard extends StatefulWidget {
//   final VendorModel vendorModel;
//   final double cardWidth;
//   final double cardHeight;
//   final VoidCallback onTap;
//
//   const _RestaurantCard({
//     required this.vendorModel,
//     required this.cardWidth,
//     required this.cardHeight,
//     required this.onTap,
//   });
//
//   @override
//   State<_RestaurantCard> createState() => _RestaurantCardState();
// }
//
// class _RestaurantCardState extends State<_RestaurantCard>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _scaleCtrl;
//
//   // Cached values — computed once, not on every build
//   late final bool _isClosed;
//   late final double _rating;
//   late final String _distanceText;
//   late final String _deliveryTime;
//   late final String? _offerLabel;
//
//   @override
//   void initState() {
//     super.initState();
//     final v = widget.vendorModel;
//
//     _isClosed = !RestaurantStatusUtils.canAcceptOrders(v);
//     _rating = _parseRating(v);
//     _distanceText = _buildDistanceText(v);
//     _deliveryTime = Constant.getDeliveryTimeText(v);
//
//     final raw = v.offer_lable?.trim() ?? '';
//     _offerLabel = raw.isNotEmpty ? raw : null;
//
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
//   // ── Helpers ──────────────────────────────────────────────
//
//   static double _parseRating(VendorModel v) {
//     final count = int.tryParse(v.reviewsCount?.toString() ?? '0') ?? 0;
//     final sum = double.tryParse(v.reviewsSum?.toString() ?? '0') ?? 0.0;
//     if (count == 0) return 0.0;
//     return (sum / count).clamp(0.0, 5.0);
//   }
//
//   static String _buildDistanceText(VendorModel v) {
//     if (v.distance != null && v.distance! > 0) {
//       return '${v.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
//     }
//     return '${Constant.getDistanceFromVendor(v)} ${Constant.distanceType}';
//   }
//
//   // ── Build ─────────────────────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     final v = widget.vendorModel;
//
//     return GestureDetector(
//       onTapDown: _isClosed ? null : (_) => _scaleCtrl.reverse(),
//       onTapUp: _isClosed
//           ? null
//           : (_) {
//               _scaleCtrl.forward();
//               widget.onTap();
//             },
//       onTapCancel: _isClosed ? null : () => _scaleCtrl.forward(),
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
//                 // ── Image + Badges ──────────────────────────
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
//                     // Offer badge — only rendered if backend sent a label
//                     if (_offerLabel != null)
//                       Positioned(
//                         left: 8,
//                         bottom: 8,
//                         child: _PromoBadge(label: _offerLabel!),
//                       ),
//
//                     // Rating badge — only rendered if restaurant has reviews
//                     if (_rating > 0)
//                       Positioned(
//                         top: 8,
//                         left: 8,
//                         child: _RatingBadge(rating: _rating),
//                       ),
//                   ],
//                 ),
//
//                 // ── Info ─────────────────────────────────────
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
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.access_time_filled,
//                                   size: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   _deliveryTime,
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
//                                     _distanceText,
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
//                         // Bottom status badge
//                         if (_isClosed)
//                           _ClosedBadge()
//                         else
//                           _DeliveryToggleBadge(deliveryTime: _deliveryTime),
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
// }
//
// // ─────────────────────────────────────────────────────────────
// //  PROMO BADGE
// //  Color is derived from the label text sent by backend.
// //  Falls back to brand primary color for unknown labels.
// // ─────────────────────────────────────────────────────────────
//
// class _PromoBadge extends StatelessWidget {
//   final String label;
//
//   const _PromoBadge({required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.72),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.local_offer, size: 10, color: Colors.white),
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
// //  RATING BADGE — uses real computed rating, no Random()
// // ─────────────────────────────────────────────────────────────
//
// class _RatingBadge extends StatelessWidget {
//   final double rating;
//
//   const _RatingBadge({required this.rating});
//
//   Color get _starColor {
//     if (rating >= 4.0) return Colors.green;
//     if (rating >= 3.0) return Colors.orange;
//     return Colors.red;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.75),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.star, size: 10, color: _starColor),
//           const SizedBox(width: 2),
//           Text(
//             rating.toStringAsFixed(1),
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
// //  CLOSED BADGE
// // ─────────────────────────────────────────────────────────────
//
// class _ClosedBadge extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: const Text(
//         'Temporarily Closed',
//         style: TextStyle(
//           fontSize: 9,
//           fontWeight: FontWeight.w600,
//           color: Colors.red,
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────
// //  DELIVERY TOGGLE BADGE
// //  Alternates between delivery time and "Fast Delivery" every 3s.
// // ─────────────────────────────────────────────────────────────
//
// class _DeliveryToggleBadge extends StatefulWidget {
//   final String deliveryTime;
//
//   const _DeliveryToggleBadge({required this.deliveryTime});
//
//   @override
//   State<_DeliveryToggleBadge> createState() => _DeliveryToggleBadgeState();
// }
//
// class _DeliveryToggleBadgeState extends State<_DeliveryToggleBadge> {
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
//       transitionBuilder: (child, animation) => FadeTransition(
//         opacity: animation,
//         child: SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(0, 0.2),
//             end: Offset.zero,
//           ).animate(animation),
//           child: child,
//         ),
//       ),
//       child: _showFastDelivery
//           ? _badge(
//               key: const ValueKey('fast'),
//               icon: Icons.flash_on,
//               label: 'Fast Delivery',
//               color: Colors.green,
//             )
//           : _badge(
//               key: const ValueKey('time'),
//               icon: Icons.access_time,
//               label: widget.deliveryTime,
//               color: Colors.orange,
//             ),
//     );
//   }
//
//   Widget _badge({
//     required Key key,
//     required IconData icon,
//     required String label,
//     required Color color,
//   }) {
//     return Container(
//       key: key,
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 12, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 9,
//               fontWeight: FontWeight.w600,
//               color: color,
//             ),
//           ),
//         ],
//       ),
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
//  GRADIENT CONSTANTS
// ─────────────────────────────────────────────────────────────

// final _kGradStart = Colors.lightBlueAccent.withOpacity(
//   0.35,
// ); // very light (top)
// final _kGradMid = Colors.lightBlueAccent.withOpacity(0.15); // medium
// final _kGradEnd = Colors.lightBlueAccent.withOpacity(0.05); // stronger (bottom)

final _kSectionGradient = const LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0x3833B5E5), // ~0.45 opacity
    Color(0x3833B5E5), // ~0.22
    Color(0x1A33B5E5), // ~0.10
    Color(0x0D33B5E5), // ~0.05
  ],
  stops: [0.0, 0.3, 0.7, 1.0],
);
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

            // ── Entire section sits on the gradient ──────────────
            return Container(
              decoration: BoxDecoration(
                gradient: _kSectionGradient,
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context,
                    filteredRestaurantList,
                    restaurantListProvider,
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 20),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT — Title
          Text(
            "Best Restaurants",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: AppThemeData.bold,
              color: AppThemeData.surfaceDark,
              letterSpacing: -0.3,
            ),
          ),

          // RIGHT — See all pill
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.45)),
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
                          color: AppThemeData.surfaceDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppThemeData.surfaceDark,
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

    // No extra Container/gradient here — parent already provides it
    return Column(
      children: [
        _SmoothCarousel(
          items: widget.firstRowItems,
          controller: _row1Controller,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          onTap: widget.onRestaurantTap,
        ),
        const SizedBox(height: 16),
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
                  color: Colors.black.withOpacity(0.10),
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

                    // Offer badge
                    if (_offerLabel != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _PromoBadge(label: _offerLabel!),
                      ),

                    // Rating badge
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
                          const _ClosedBadge()
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
//  RATING BADGE
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
  const _ClosedBadge();

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
