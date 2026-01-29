// import 'dart:math' show cos, sin;
//
// import 'package:jippymart_customer/app/advertisement_screens/all_advertisement_screen.dart';
// import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
// import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
// import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
// import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
// import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart'
//     show BestRestaurantProvider;
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/banner_view_widget.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/bottom_banner_view_widget.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/best_restaurant_section_widget.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_profile_widget.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_screen_search_widget.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/mart_food_tab_bar_widget.dart';
// import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
// import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
// import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
// import 'package:jippymart_customer/app/DealsScreen/DealsScreen.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/advertisement_model.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/services/cart_provider.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:jippymart_customer/utils/fire_store_utils.dart';
// import 'package:jippymart_customer/utils/network_image_widget.dart';
// import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
// import 'package:jippymart_customer/utils/utils/image_const.dart';
// import 'package:jippymart_customer/widget/filter_bar.dart';
// import 'package:jippymart_customer/widget/mini_cart_bar.dart';
// import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
// import 'package:jippymart_customer/widget/video_widget.dart';
// import 'package:jippymart_customer/widgets/app_loading_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'widgets/category_view_widget.dart';
//
// class HomeScreenTwo extends StatelessWidget {
//   const HomeScreenTwo({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer4<
//       HomeProvider,
//       MartProvider,
//       MartNavigationProvider,
//       BestRestaurantProvider
//     >(
//       builder:
//           (
//             context,
//             controller,
//             martProvider,
//             martNavigationProvider,
//             bestRestaurantProvider,
//             _,
//           ) {
//             return Scaffold(
//               body: Container(
//                 decoration: BoxDecoration(
//                   image: DecorationImage(
//                     image: AssetImage(ImageConst.backgroundImage),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     controller.getRefresh(context);
//                   },
//                   child:
//                       (controller.isLoading || !controller.zoneCheckCompleted)
//                       ? const RestaurantLoadingWidget()
//                       : controller.hasActuallyCheckedZone &&
//                             Constant.isZoneAvailable == false &&
//                             (bestRestaurantProvider
//                                     .allNearestRestaurant
//                                     .isEmpty ||
//                                 bestRestaurantProvider
//                                     .bestRestaurantList
//                                     .isEmpty)
//                       ? Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 "assets/images/location.gif",
//                                 height: 120,
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 Constant.isZoneAvailable == false
//                                     ? "Service Not Available in Your Area".tr
//                                     : "No Restaurants Found in Your Area".tr,
//                                 style: TextStyle(
//                                   color: AppThemeData.grey800,
//                                   fontSize: 22,
//                                   fontFamily: AppThemeData.semiBold,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 Constant.isZoneAvailable == false
//                                     ? "We don't currently deliver to your location. Please try a different address within our service area."
//                                           .tr
//                                     : "Currently, there are no available restaurants in your zone. Try changing your location to find nearby options."
//                                           .tr,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: AppThemeData.grey500,
//                                   fontSize: 16,
//                                   fontFamily: AppThemeData.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               RoundedButtonFill(
//                                 title: "Change Zone".tr,
//                                 width: 55,
//                                 height: 5.5,
//                                 color: AppThemeData.primary300,
//                                 textColor: AppThemeData.grey50,
//                                 onPress: () async {
//                                   Get.offAll(() => LocationPermissionScreen());
//                                 },
//                               ),
//                             ],
//                           ),
//                         )
//                       : Padding(
//                           padding: EdgeInsets.only(
//                             top: MediaQuery.of(context).viewPadding.top,
//                           ),
//                           child: Column(
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     martFoodTabBarWidgetHome(
//                                       martProvider: martProvider,
//                                       martNavigationProvider:
//                                           martNavigationProvider,
//                                       context: context,
//                                     ),
//                                     homeProfileAddressWidget(
//                                       homeProvider: controller,
//                                       context: context,
//                                     ),
//                                     const SizedBox(height: 20),
//                                     homeScreenSearchWidget(),
//                                     const SizedBox(height: 10),
//                                   ],
//                                 ),
//                               ),
//                               Expanded(
//                                 child: SingleChildScrollView(
//                                   child: Column(
//                                     children: [
//                                       controller.bannerModel.isEmpty
//                                           ? const SizedBox()
//                                           : Padding(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                     horizontal: 16,
//                                                   ),
//                                               child: BannerView(),
//                                             ),
//                                       const SizedBox(height: 20),
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 16,
//                                         ),
//                                         // child: CategoryView(),
//                                       ),
//                                       // Celebratory "Grab The DEALS" Banner
//                                       _buildDealsBanner(context),
//                                       BestRestaurantsSection(
//                                         restaurantList: bestRestaurantProvider
//                                             .bestRestaurantList,
//                                       ),
//                                       Visibility(
//                                         visible:
//                                             Constant.isEnableAdsFeature == true,
//                                         child:
//                                             bestRestaurantProvider
//                                                 .advertisementList
//                                                 .isEmpty
//                                             ? const SizedBox()
//                                             : Column(
//                                                 children: [
//                                                   const SizedBox(height: 20),
//                                                   Container(
//                                                     margin:
//                                                         const EdgeInsets.symmetric(
//                                                           horizontal: 16,
//                                                         ),
//                                                     padding:
//                                                         const EdgeInsets.symmetric(
//                                                           horizontal: 16,
//                                                           vertical: 16,
//                                                         ),
//                                                     decoration: BoxDecoration(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                             20,
//                                                           ),
//                                                       color: AppThemeData
//                                                           .primary300
//                                                           .withAlpha(40),
//                                                     ),
//                                                     child: Column(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .start,
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         Row(
//                                                           children: [
//                                                             Expanded(
//                                                               child: Text(
//                                                                 "Highlights for you"
//                                                                     .tr,
//                                                                 textAlign:
//                                                                     TextAlign
//                                                                         .start,
//                                                                 style: TextStyle(
//                                                                   fontFamily:
//                                                                       AppThemeData
//                                                                           .semiBold,
//                                                                   fontSize: 16,
//                                                                   color: AppThemeData
//                                                                       .grey900,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             InkWell(
//                                                               onTap: () {
//                                                                 Get.to(
//                                                                   AllAdvertisementScreen(),
//                                                                 )?.then((
//                                                                   value,
//                                                                 ) {
//                                                                   controller
//                                                                       .getFavouriteRestaurant();
//                                                                 });
//                                                               },
//                                                               child: Text(
//                                                                 "See all".tr,
//                                                                 textAlign:
//                                                                     TextAlign
//                                                                         .center,
//                                                                 style: TextStyle(
//                                                                   fontFamily:
//                                                                       AppThemeData
//                                                                           .regular,
//                                                                   color: AppThemeData
//                                                                       .primary300,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                         const SizedBox(
//                                                           height: 16,
//                                                         ),
//                                                         SizedBox(
//                                                           height: 220,
//                                                           child: ListView.builder(
//                                                             physics:
//                                                                 const BouncingScrollPhysics(),
//                                                             scrollDirection:
//                                                                 Axis.horizontal,
//                                                             itemCount:
//                                                                 bestRestaurantProvider
//                                                                         .advertisementList
//                                                                         .length >=
//                                                                     6
//                                                                 ? 6
//                                                                 : bestRestaurantProvider
//                                                                       .advertisementList
//                                                                       .length,
//                                                             padding:
//                                                                 EdgeInsets.all(
//                                                                   0,
//                                                                 ),
//                                                             itemBuilder:
//                                                                 (
//                                                                   BuildContext
//                                                                   context,
//                                                                   int index,
//                                                                 ) {
//                                                                   return AdvertisementHomeCard(
//                                                                     controller:
//                                                                         controller,
//                                                                     model: bestRestaurantProvider
//                                                                         .advertisementList[index],
//                                                                   );
//                                                                 },
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                       ),
//                                       // Banners section between Best Restaurants and All Restaurants - same as top with auto-scroll
//                                       controller.bannerBottomModel.isEmpty
//                                           ? const SizedBox()
//                                           : Padding(
//                                               padding: const EdgeInsets.only(
//                                                 top: 20,
//                                                 left: 16,
//                                                 right: 16,
//                                                 bottom: 0,
//                                               ),
//                                               child: BottomBannerView(),
//                                             ),
//                                       const SizedBox(height: 20),
//                                       _buildAllRestaurantsSection(
//                                         bestRestaurantProvider,
//                                         controller,
//                                         context,
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
//               floatingActionButton: Stack(
//                 children: [
//                   Consumer3<CartProvider, CartControllerProvider, HomeProvider>(
//                     builder:
//                         (
//                           context,
//                           cartProvider,
//                           cartControllerProvider,
//                           homeProvider,
//                           _,
//                         ) {
//                           return const Positioned(
//                             bottom: 0,
//                             left: 16,
//                             right: 0,
//                             child: MiniCartBar(),
//                           );
//                         },
//                   ),
//                   Positioned(
//                     bottom: HomeProvider.cartItem.isNotEmpty ? 100 : 16,
//                     // Position above mini cart if active, otherwise at bottom
//                     right: 0,
//                     // Consistent right margin
//                     child: FloatingActionButton(
//                       onPressed: () async {
//                         const String phoneNumber =
//                             '+919390579864'; // Your actual WhatsApp number
//                         const String message =
//                             'Hello! I need help with my order.'; // Customize the message
//                         final Uri whatsappUrl = Uri.parse(
//                           'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
//                         );
//                         try {
//                           if (await canLaunchUrl(whatsappUrl)) {
//                             await launchUrl(
//                               whatsappUrl,
//                               mode: LaunchMode.externalApplication,
//                             );
//                           } else {
//                             final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
//                             if (await canLaunchUrl(phoneUrl)) {
//                               await launchUrl(
//                                 phoneUrl,
//                                 mode: LaunchMode.externalApplication,
//                               );
//                             }
//                           }
//                         } catch (e) {
//                           print('Error launching WhatsApp: $e');
//                         }
//                       },
//                       backgroundColor: Colors.green, // WhatsApp green color
//                       child: Padding(
//                         padding: const EdgeInsets.all(0.0),
//                         child: SvgPicture.asset(
//                           'assets/images/whatsapp.svg',
//                           width: 44,
//                           height: 44,
//                           colorFilter: const ColorFilter.mode(
//                             Colors.white,
//                             BlendMode.srcIn,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//     );
//   }
//
//   /// Build celebratory "Grab The DEALS" banner with party poppers
//   Widget _buildDealsBanner(BuildContext context) {
//     const String gifPath = 'assets/images/deals_banner.gif';
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: InkWell(
//         onTap: () {
//           // Navigate to deals screen using navigation bar
//           final dashBoardProvider = Provider.of<DashBoardProvider>(context, listen: false);
//           final homeProvider = Provider.of<HomeProvider>(context, listen: false);
//           final splashProvider = Provider.of<SplashProvider>(context, listen: false);
//           final cartControllerProvider = Provider.of<CartControllerProvider>(context, listen: false);
//           final orderProvider = Provider.of<OrderProvider>(context, listen: false);
//           final favouriteProvider = Provider.of<FavouriteProvider>(context, listen: false);
//
//           // Navigate to deals screen (index 2) using navigation bar
//           dashBoardProvider.changeNavbar(
//             2, // Deals screen index
//             homeProvider,
//             splashProvider,
//             cartControllerProvider,
//             orderProvider,
//             context,
//             favouriteProvider,
//           );
//         },
//         borderRadius: BorderRadius.circular(20),
//         child: Container(
//           height: 70,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//               colors: [Colors.purple, AppThemeData.primary300.withOpacity(0.8)],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: AppThemeData.primary300.withOpacity(0.3),
//                 blurRadius: 12,
//                 spreadRadius: 2,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Stack(
//             children: [
//               // GIF background with proper error handling
//               // ClipRRect(
//               //   borderRadius: BorderRadius.circular(20),
//               //   child: Image.asset(
//               //     gifPath,
//               //     width: double.infinity,
//               //     height: 70,
//               //     fit: BoxFit.cover,
//               //     gaplessPlayback: true,
//               //     frameBuilder:
//               //         (context, child, frame, wasSynchronouslyLoaded) {
//               //           if (wasSynchronouslyLoaded) {
//               //             return child;
//               //           }
//               //           return AnimatedSwitcher(
//               //             duration: const Duration(milliseconds: 300),
//               //             child: frame != null
//               //                 ? child
//               //                 : Container(
//               //                     key: const ValueKey('loading'),
//               //                     decoration: BoxDecoration(
//               //                       gradient: LinearGradient(
//               //                         begin: Alignment.centerLeft,
//               //                         end: Alignment.centerRight,
//               //                         colors: [
//               //                           Colors.purple,
//               //                           AppThemeData.primary300.withOpacity(
//               //                             0.8,
//               //                           ),
//               //                         ],
//               //                       ),
//               //                       borderRadius: BorderRadius.circular(20),
//               //                     ),
//               //                   ),
//               //           );
//               //         },
//               //     errorBuilder: (context, error, stackTrace) {
//               //       print('[DEALS_BANNER] Error loading GIF: $error');
//               //       print('[DEALS_BANNER] Stack trace: $stackTrace');
//               //       // If GIF doesn't exist, show gradient background
//               //       return Container(
//               //         decoration: BoxDecoration(
//               //           gradient: LinearGradient(
//               //             begin: Alignment.centerLeft,
//               //             end: Alignment.centerRight,
//               //             colors: [
//               //               Colors.purple,
//               //               AppThemeData.primary300.withOpacity(0.8),
//               //             ],
//               //           ),
//               //           borderRadius: BorderRadius.circular(20),
//               //         ),
//               //       );
//               //     },
//               //   ),
//               // ),
//               // Gradient overlay for better text visibility (very light overlay)
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                     colors: [
//                       Colors.purple.withOpacity(0.2),
//                       AppThemeData.primary300.withOpacity(0.15),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               // GIF on left side
//               Positioned(
//                 left: 0,
//                 top: 0,
//                 bottom: 0,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     bottomLeft: Radius.circular(20),
//                   ),
//                   child: Image.asset(
//                     gifPath,
//                     width: 60,
//                     height: 70,
//                     fit: BoxFit.cover,
//                     gaplessPlayback: true,
//                     errorBuilder: (context, error, stackTrace) {
//                       return SizedBox(width: 60);
//                     },
//                   ),
//                 ),
//               ),
//               // GIF on right side (flipped 180 degrees)
//               Positioned(
//                 right: 0,
//                 top: 0,
//                 bottom: 0,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.only(
//                     topRight: Radius.circular(20),
//                     bottomRight: Radius.circular(20),
//                   ),
//                   child: Transform(
//                     alignment: Alignment.center,
//                     transform: Matrix4.rotationY(3.14159),
//                     // 180 degrees rotation
//                     child: Image.asset(
//                       gifPath,
//                       width: 60,
//                       height: 70,
//                       fit: BoxFit.cover,
//                       gaplessPlayback: true,
//                       errorBuilder: (context, error, stackTrace) {
//                         return SizedBox(width: 60);
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               // Main content
//               Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 70),
//                   child: Text(
//                     "Grab The DEALS",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       // Gold/yellow
//                       letterSpacing: 1.2,
//                       shadows: [
//                         Shadow(
//                           color: Colors.black.withOpacity(0.3),
//                           offset: Offset(0, 2),
//                           blurRadius: 4,
//                         ),
//                       ],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Build party popper widget with confetti burst
//   Widget _buildPartyPopper() {
//     return CustomPaint(painter: PartyPopperPainter(), size: Size(40, 40));
//   }
//
//   Widget _buildAllRestaurantsSection(
//     BestRestaurantProvider bestRestaurantProvider,
//     HomeProvider controller,
//     BuildContext context,
//   ) {
//     final allRestaurants = bestRestaurantProvider.allNearestRestaurant;
//     if (allRestaurants.isEmpty) {
//       return const SizedBox();
//     }
//     return Consumer<RestaurantDetailsProvider>(
//       builder: (context, restaurantDetailsProvider, _) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
//               child: Text(
//                 "All Restaurants",
//                 style: TextStyle(
//                   fontFamily: AppThemeData.medium,
//                   color: AppThemeData.grey900,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16.0,
//                 vertical: 8.0,
//               ),
//               child: FilterBar(
//                 selectedFilters: {},
//                 onFilterToggled: (filter) {
//                   String? apiFilter;
//                   switch (filter) {
//                     case FilterType.distance:
//                       apiFilter = 'distance';
//                       break;
//                     case FilterType.rating:
//                       apiFilter = 'rating';
//                       break;
//                     case FilterType.priceLowToHigh:
//                     case FilterType.priceHighToLow:
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             'This filter is currently not available',
//                           ),
//                           duration: Duration(seconds: 2),
//                         ),
//                       );
//                       return;
//                   }
//                   bestRestaurantProvider.applyFilter(apiFilter);
//                 },
//                 availableFilters: bestRestaurantProvider.availableFilters,
//                 currentFilter: bestRestaurantProvider.currentFilter,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   return GridView.builder(
//                     shrinkWrap: true,
//                     primary: false,
//                     padding: EdgeInsets.zero,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: allRestaurants.length,
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 3,
//                           crossAxisSpacing: 6,
//                           mainAxisSpacing: 8,
//                           childAspectRatio: 0.65,
//                         ),
//                     itemBuilder: (BuildContext context, int index) {
//                       final vendorModel = allRestaurants[index];
//                       final isClosed = !RestaurantStatusUtils.canAcceptOrders(
//                         vendorModel,
//                       );
//                       return InkWell(
//                         onTap: isClosed
//                             ? null
//                             : () {
//                                 restaurantDetailsProvider.initFunction(
//                                   vendorModels: vendorModel,
//                                 );
//                                 Get.to(const RestaurantDetailsScreen());
//                               },
//                         borderRadius: BorderRadius.circular(16),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: AppThemeData.grey50,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Stack(
//                             children: [
//                               // Main Content
//                               Padding(
//                                 padding: const EdgeInsets.all(8),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // Image Section
//                                     AspectRatio(
//                                       aspectRatio: 1,
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                           color: AppThemeData.grey200
//                                               .withOpacity(0.5),
//                                         ),
//                                         child: Stack(
//                                           children: [
//                                             // Restaurant Image
//                                             ClipRRect(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                               child: RestaurantImageWithStatus(
//                                                 vendorModel: vendorModel,
//                                                 height: double.infinity,
//                                                 width: double.infinity,
//                                               ),
//                                             ),
//                                             // Status Badge
//                                             Positioned(
//                                               top: 6,
//                                               left: 6,
//                                               child: _buildEnhancedStatusBadge(
//                                                 vendorModel,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Text(
//                                       vendorModel.title ?? 'Restaurant',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontFamily: AppThemeData.semiBold,
//                                         color: AppThemeData.grey900,
//                                         height: 1.2,
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     const Spacer(),
//                                     _buildBottomInfoRow(vendorModel),
//                                   ],
//                                 ),
//                               ),
//                               if (isClosed) ...[
//                                 Positioned.fill(
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withOpacity(0.4),
//                                       borderRadius: BorderRadius.circular(16),
//                                     ),
//                                     child: Center(
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.black.withOpacity(0.7),
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           'CLOSED',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 10,
//                                             fontFamily: AppThemeData.bold,
//                                             letterSpacing: 0.5,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildEnhancedStatusBadge(VendorModel vendorModel) {
//     final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);
//
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
//   Widget _buildBottomInfoRow(VendorModel vendorModel) {
//     return Row(
//       children: [
//         // Rating
//         Expanded(
//           child: Row(
//             children: [
//               Icon(Icons.star, size: 12, color: AppThemeData.primary300),
//               const SizedBox(width: 2),
//               Expanded(
//                 child: Text(
//                   "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount?.toStringAsFixed(0) ?? '0'})",
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
//         // Distance (if available)
//         if (vendorModel.distance != null) ...[
//           const SizedBox(width: 4),
//           Expanded(
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.location_on_outlined,
//                   size: 10,
//                   color: AppThemeData.grey400,
//                 ),
//                 const SizedBox(width: 2),
//                 Expanded(
//                   child: Text(
//                     "${(vendorModel.distance ?? 0).toStringAsFixed(1)} km",
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontFamily: AppThemeData.medium,
//                       color: AppThemeData.grey500,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }
//
// class AdvertisementHomeCard extends StatelessWidget {
//   final AdvertisementModel model;
//   final HomeProvider controller;
//
//   const AdvertisementHomeCard({
//     super.key,
//     required this.controller,
//     required this.model,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<RestaurantDetailsProvider>(
//       builder: (context, restaurantDetailsProvider, _) {
//         return InkWell(
//           onTap: () async {
//             ShowToastDialog.showLoader("Please wait".tr);
//             VendorModel? vendorModel = await FireStoreUtils.getVendorById(
//               model.vendorId!,
//             );
//             ShowToastDialog.closeLoader();
//             restaurantDetailsProvider.initFunction(
//               vendorModels: vendorModel ?? VendorModel(),
//             );
//             Get.to(const RestaurantDetailsScreen());
//           },
//           child: Container(
//             margin: EdgeInsets.only(right: 16),
//             width: Responsive.width(70, context),
//             decoration: BoxDecoration(
//               color: AppThemeData.surface,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 2,
//                   spreadRadius: 0,
//                   offset: Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Stack(
//                   children: [
//                     model.type == 'restaurant_promotion'
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.vertical(
//                               top: Radius.circular(16),
//                             ),
//                             child: NetworkImageWidget(
//                               imageUrl: model.coverImage ?? '',
//                               height: 135,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                         : VideoAdvWidget(
//                             url: model.video ?? '',
//                             height: 135,
//                             width: double.infinity,
//                           ),
//                     if (model.type != 'video_promotion' &&
//                         model.vendorId != null &&
//                         (model.showRating == true || model.showReview == true))
//                       Positioned(
//                         bottom: 8,
//                         right: 8,
//                         child: FutureBuilder(
//                           future: FireStoreUtils.getVendorById(model.vendorId!),
//                           builder: (context, snapshot) {
//                             if (snapshot.connectionState ==
//                                 ConnectionState.waiting) {
//                               return const SizedBox();
//                             } else {
//                               if (snapshot.hasError) {
//                                 return const SizedBox();
//                               } else if (snapshot.data == null) {
//                                 return const SizedBox();
//                               } else {
//                                 VendorModel vendorModel = snapshot.data!;
//                                 return Container(
//                                   decoration: ShapeDecoration(
//                                     color: AppThemeData.primary50,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(120),
//                                     ),
//                                   ),
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         SvgPicture.asset(
//                                           "assets/icons/ic_star.svg",
//                                           colorFilter: ColorFilter.mode(
//                                             AppThemeData.primary300,
//                                             BlendMode.srcIn,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 5),
//                                         Text(
//                                           "${model.showRating == true ? Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString()) : ''} ${model.showReview == true ? '(${vendorModel.reviewsCount!.toStringAsFixed(0)})' : ''}",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: AppThemeData.primary300,
//                                             fontFamily: AppThemeData.semiBold,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               }
//                             }
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//                 Padding(
//                   padding: EdgeInsets.all(12),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (model.type == 'restaurant_promotion')
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(30),
//                           child: NetworkImageWidget(
//                             imageUrl: model.profileImage ?? '',
//                             height: 50,
//                             width: 50,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               model.title ?? '',
//                               style: TextStyle(
//                                 color: AppThemeData.grey900,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             Text(
//                               model.description ?? '',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontFamily: AppThemeData.medium,
//                                 color: AppThemeData.grey600,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 2,
//                             ),
//                           ],
//                         ),
//                       ),
//                       // model.type == 'restaurant_promotion'
//                       //     ? IconButton(
//                       //         icon: Obx(
//                       //           () =>
//                       //               controller.favouriteList
//                       //                   .where(
//                       //                     (p0) => p0.restaurantId == model.vendorId,
//                       //                   )
//                       //                   .isNotEmpty
//                       //               ? SvgPicture.asset(
//                       //                   "assets/icons/ic_like_fill.svg",
//                       //                 )
//                       //               : SvgPicture.asset(
//                       //                   "assets/icons/ic_like.svg",
//                       //                   colorFilter: ColorFilter.mode(
//                       //                     AppThemeData.grey600,
//                       //                     BlendMode.srcIn,
//                       //                   ),
//                       //                 ),
//                       //         ),
//                       //         onPressed: () async {
//                       //           final userId =
//                       //               await SqlStorageConst.getFirebaseId();
//                       //           if (controller.favouriteList
//                       //               .where(
//                       //                 (p0) => p0.restaurantId == model.vendorId,
//                       //               )
//                       //               .isNotEmpty) {
//                       //             FavouriteModel favouriteModel = FavouriteModel(
//                       //               restaurantId: model.vendorId,
//                       //               userId: userId,
//                       //             );
//                       //             controller.favouriteList.removeWhere(
//                       //               (item) => item.restaurantId == model.vendorId,
//                       //             );
//                       //             await FireStoreUtils.removeFavouriteRestaurant(
//                       //               favouriteModel,
//                       //             );
//                       //           } else {
//                       //             FavouriteModel favouriteModel = FavouriteModel(
//                       //               restaurantId: model.vendorId,
//                       //               userId: userId,
//                       //             );
//                       //             controller.favouriteList.add(favouriteModel);
//                       //             await FireStoreUtils.setFavouriteRestaurant(
//                       //               favouriteModel,
//                       //             );
//                       //           }
//                       //         },
//                       //       )
//                       //     :         // model.type == 'restaurant_promotion'
//                       //     ? IconButton(
//                       //         icon: Obx(
//                       //           () =>
//                       //               controller.favouriteList
//                       //                   .where(
//                       //                     (p0) => p0.restaurantId == model.vendorId,
//                       //                   )
//                       //                   .isNotEmpty
//                       //               ? SvgPicture.asset(
//                       //                   "assets/icons/ic_like_fill.svg",
//                       //                 )
//                       //               : SvgPicture.asset(
//                       //                   "assets/icons/ic_like.svg",
//                       //                   colorFilter: ColorFilter.mode(
//                       //                     AppThemeData.grey600,
//                       //                     BlendMode.srcIn,
//                       //                   ),
//                       //                 ),
//                       //         ),
//                       //         onPressed: () async {
//                       //           final userId =
//                       //               await SqlStorageConst.getFirebaseId();
//                       //           if (controller.favouriteList
//                       //               .where(
//                       //                 (p0) => p0.restaurantId == model.vendorId,
//                       //               )
//                       //               .isNotEmpty) {
//                       //             FavouriteModel favouriteModel = FavouriteModel(
//                       //               restaurantId: model.vendorId,
//                       //               userId: userId,
//                       //             );
//                       //             controller.favouriteList.removeWhere(
//                       //               (item) => item.restaurantId == model.vendorId,
//                       //             );
//                       //             await FireStoreUtils.removeFavouriteRestaurant(
//                       //               favouriteModel,
//                       //             );
//                       //           } else {
//                       //             FavouriteModel favouriteModel = FavouriteModel(
//                       //               restaurantId: model.vendorId,
//                       //               userId: userId,
//                       //             );
//                       //             controller.favouriteList.add(favouriteModel);
//                       //             await FireStoreUtils.setFavouriteRestaurant(
//                       //               favouriteModel,
//                       //             );
//                       //           }
//                       //         },
//                       //       )
//                       //     :
//                       Container(
//                         decoration: ShapeDecoration(
//                           color: AppThemeData.primary50,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(5),
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 4,
//                           ),
//                           child: Icon(
//                             Icons.arrow_forward,
//                             size: 20,
//                             color: AppThemeData.primary300,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// /// Animated party popper widget with continuous animation
// class _AnimatedPartyPopper extends StatefulWidget {
//   final double? size;
//   final double angle;
//
//   const _AnimatedPartyPopper({this.size, this.angle = 0.0});
//
//   @override
//   State<_AnimatedPartyPopper> createState() => _AnimatedPartyPopperState();
// }
//
// class _AnimatedPartyPopperState extends State<_AnimatedPartyPopper>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _rotationAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _opacityAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     )..repeat(reverse: true);
//
//     _rotationAnimation = Tween<double>(
//       begin: widget.angle - 0.2,
//       end: widget.angle + 0.2,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//
//     _scaleAnimation = Tween<double>(
//       begin: 0.9,
//       end: 1.1,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//
//     _opacityAnimation = Tween<double>(
//       begin: 0.7,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Transform.rotate(
//           angle: _rotationAnimation.value,
//           child: Transform.scale(
//             scale: _scaleAnimation.value,
//             child: Opacity(
//               opacity: _opacityAnimation.value,
//               child: Container(
//                 width: widget.size ?? 40,
//                 height: widget.size ?? 40,
//                 child: CustomPaint(
//                   painter: PartyPopperPainter(
//                     animationValue: _controller.value,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// /// Custom painter for party popper with confetti burst
// class PartyPopperPainter extends CustomPainter {
//   final double animationValue;
//
//   PartyPopperPainter({this.animationValue = 0.0});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..style = PaintingStyle.fill;
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//
//     // Draw party popper cone (pointing diagonally)
//     paint.color = Colors.white;
//     final path = Path();
//     // Cone shape pointing from bottom-left to top-right
//     path.moveTo(centerX - 8, centerY + 8); // Bottom-left
//     path.lineTo(centerX - 4, centerY - 4); // Top-left
//     path.lineTo(centerX + 4, centerY - 8); // Top-right
//     path.lineTo(centerX + 8, centerY + 4); // Bottom-right
//     path.close();
//     canvas.drawPath(path, paint);
//
//     // Draw confetti burst from the opening with animation
//     final confettiColors = [
//       Color(0xFFFFD700), // Gold
//       Color(0xFFFFD700), // Gold
//       Colors.white,
//       Colors.white,
//     ];
//
//     // Animated confetti distance based on animation value
//     final baseDistance = 12.0;
//     final animatedDistance = baseDistance + (animationValue * 4.0);
//
//     // Draw confetti pieces (small circles and lines) with animation
//     for (int i = 0; i < 8; i++) {
//       final angle = (i * 3.14159 * 2) / 8 + (animationValue * 0.5);
//       final distance = animatedDistance;
//       final x = centerX + 2 + distance * cos(angle);
//       final y = centerY - 6 + distance * sin(angle);
//
//       paint.color = confettiColors[i % confettiColors.length];
//
//       // Draw small circles (confetti) with pulsing effect
//       if (i % 2 == 0) {
//         final radius = 2.0 + (animationValue * 0.5);
//         canvas.drawCircle(Offset(x, y), radius, paint);
//       } else {
//         // Draw small lines (confetti streaks) with rotation
//         final linePaint = Paint()
//           ..color = Colors.white
//           ..strokeWidth = 1.5 + (animationValue * 0.3)
//           ..style = PaintingStyle.stroke;
//         final lineAngle = angle + (animationValue * 1.0);
//         final lineLength = 4.0 + (animationValue * 2.0);
//         canvas.drawLine(
//           Offset(
//             x - lineLength * cos(lineAngle),
//             y - lineLength * sin(lineAngle),
//           ),
//           Offset(
//             x + lineLength * cos(lineAngle),
//             y + lineLength * sin(lineAngle),
//           ),
//           linePaint,
//         );
//       }
//     }
//
//     // Draw animated star shape
//     paint.color = Colors.white;
//     final starX = centerX + 6 + (animationValue * 2.0);
//     final starY = centerY - 8 - (animationValue * 2.0);
//     final starSize = 4.0 + (animationValue * 1.0);
//     _drawStar(canvas, Offset(starX, starY), starSize, paint);
//   }
//
//   void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
//     final path = Path();
//     for (int i = 0; i < 5; i++) {
//       final angle = (i * 4 * 3.14159) / 5 - 3.14159 / 2;
//       final x = center.dx + radius * cos(angle);
//       final y = center.dy + radius * sin(angle);
//       if (i == 0) {
//         path.moveTo(x, y);
//       } else {
//         path.lineTo(x, y);
//       }
//     }
//     path.close();
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'dart:math' show cos, sin;
import 'package:jippymart_customer/app/advertisement_screens/all_advertisement_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart'
    show BestRestaurantProvider;
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/bottom_banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/best_restaurant_section_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_profile_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_screen_search_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/mart_food_tab_bar_widget.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/app/DealsScreen/DealsScreen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/filter_bar.dart';
import 'package:jippymart_customer/widget/mini_cart_bar.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:jippymart_customer/widget/video_widget.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/category_view_widget.dart';

class HomeScreenTwo extends StatelessWidget {
  const HomeScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      HomeProvider,
      MartProvider,
      MartNavigationProvider,
      BestRestaurantProvider
    >(
      builder:
          (
            context,
            controller,
            martProvider,
            martNavigationProvider,
            bestRestaurantProvider,
            _,
          ) {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(ImageConst.backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await controller.getRefresh(context);
                  },
                  child: _buildContent(
                    controller,
                    bestRestaurantProvider,
                    context,
                  ),
                ),
              ),
              floatingActionButton: _buildWhatsAppFAB(),
            );
          },
    );
  }

  Widget _buildContent(
    HomeProvider controller,
    BestRestaurantProvider bestRestaurantProvider,
    BuildContext context,
  ) {
    if (controller.isLoading || !controller.zoneCheckCompleted) {
      return const RestaurantLoadingWidget();
    }

    if (controller.hasActuallyCheckedZone &&
        Constant.isZoneAvailable == false &&
        bestRestaurantProvider.allNearestRestaurant.isEmpty) {
      return _buildNoServiceWidget(context);
    }

    return _buildMainContent(controller, bestRestaurantProvider, context);
  }

  Widget _buildNoServiceWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/location.gif", height: 120),
          const SizedBox(height: 12),
          Text(
            Constant.isZoneAvailable == false
                ? "Service Not Available in Your Area".tr
                : "No Restaurants Found in Your Area".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            Constant.isZoneAvailable == false
                ? "We don't currently deliver to your location. Please try a different address within our service area."
                      .tr
                : "Currently, there are no available restaurants in your zone. Try changing your location to find nearby options."
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
            title: "Change Zone".tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () {
              Get.offAll(() => const LocationPermissionScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    HomeProvider controller,
    BestRestaurantProvider bestRestaurantProvider,
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMartFoodTabBar(context),
                homeProfileAddressWidget(
                  homeProvider: controller,
                  context: context,
                ),
                const SizedBox(height: 20),
                homeScreenSearchWidget(),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBannerSection(controller),
                  const SizedBox(height: 20),
                  _buildDealsBanner(context),
                  BestRestaurantsSection(
                    restaurantList: bestRestaurantProvider.bestRestaurantList,
                  ),
                  _buildAdvertisementSection(
                    bestRestaurantProvider,
                    controller,
                  ),
                  _buildBottomBannerSection(controller),
                  const SizedBox(height: 20),
                  _buildAllRestaurantsSection(
                    bestRestaurantProvider,
                    controller,
                    context,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMartFoodTabBar(BuildContext context) {
    return Consumer2<MartProvider, MartNavigationProvider>(
      builder: (context, martProvider, martNavigationProvider, _) {
        return martFoodTabBarWidgetHome(
          martProvider: martProvider,
          martNavigationProvider: martNavigationProvider,
          context: context,
        );
      },
    );
  }

  Widget _buildBannerSection(HomeProvider controller) {
    return controller.bannerModel.isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BannerView(),
          );
  }

  Widget _buildAdvertisementSection(
    BestRestaurantProvider bestRestaurantProvider,
    HomeProvider controller,
  ) {
    if (Constant.isEnableAdsFeature != true ||
        bestRestaurantProvider.advertisementList.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppThemeData.primary300.withAlpha(40),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Highlights for you".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color: AppThemeData.grey900,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.to(() => AllAdvertisementScreen())?.then((value) {
                        controller.getFavouriteRestaurant();
                      });
                    },
                    child: Text(
                      "See all".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.primary300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      bestRestaurantProvider.advertisementList.length >= 6
                      ? 6
                      : bestRestaurantProvider.advertisementList.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (BuildContext context, int index) {
                    return AdvertisementHomeCard(
                      controller: controller,
                      model: bestRestaurantProvider.advertisementList[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBannerSection(HomeProvider controller) {
    return controller.bannerBottomModel.isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            child: BottomBannerView(),
          );
  }

  Widget _buildDealsBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _navigateToDealsScreen(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.purple, AppThemeData.primary300.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppThemeData.primary300.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Add background and decorative elements here if needed
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/deals_banner.gif',
                    width: 60,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(width: 60);
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159),
                    child: Image.asset(
                      'assets/images/deals_banner.gif',
                      width: 60,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(width: 60);
                      },
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Text(
                    "Grab The DEALS",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDealsScreen(BuildContext context) {
    final dashBoardProvider = Provider.of<DashBoardProvider>(
      context,
      listen: false,
    );
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final cartControllerProvider = Provider.of<CartControllerProvider>(
      context,
      listen: false,
    );
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final favouriteProvider = Provider.of<FavouriteProvider>(
      context,
      listen: false,
    );

    dashBoardProvider.changeNavbar(
      2,
      // Deals screen index
      homeProvider,
      splashProvider,
      cartControllerProvider,
      orderProvider,
      context,
      favouriteProvider,
    );
  }

  Widget _buildAllRestaurantsSection(
    BestRestaurantProvider bestRestaurantProvider,
    HomeProvider controller,
    BuildContext context,
  ) {
    final allRestaurants = bestRestaurantProvider.allNearestRestaurant;
    if (allRestaurants.isEmpty) {
      return const SizedBox();
    }

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Text(
                "All Restaurants",
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: FilterBar(
                selectedFilters: {},
                onFilterToggled: (filter) => _handleFilterToggle(
                  filter,
                  bestRestaurantProvider,
                  context,
                ),
                availableFilters: bestRestaurantProvider.availableFilters,
                currentFilter: bestRestaurantProvider.currentFilter,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allRestaurants.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _buildRestaurantCard(
                    allRestaurants[index],
                    restaurantDetailsProvider,
                    context,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleFilterToggle(
    FilterType filter,
    BestRestaurantProvider bestRestaurantProvider,
    BuildContext context,
  ) {
    String? apiFilter;
    switch (filter) {
      case FilterType.distance:
        apiFilter = 'distance';
        break;
      case FilterType.rating:
        apiFilter = 'rating';
        break;
      case FilterType.priceLowToHigh:
      case FilterType.priceHighToLow:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This filter is currently not available'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
    }
    bestRestaurantProvider.applyFilter(apiFilter);
  }

  Widget _buildRestaurantCard(
    VendorModel vendorModel,
    RestaurantDetailsProvider restaurantDetailsProvider,
    BuildContext context,
  ) {
    final isClosed = !RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return InkWell(
      onTap: isClosed
          ? null
          : () {
              restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
              Get.to(() => const RestaurantDetailsScreen());
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeData.grey50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppThemeData.grey200.withOpacity(0.5),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RestaurantImageWithStatus(
                              vendorModel: vendorModel,
                              height: double.infinity,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: _buildEnhancedStatusBadge(vendorModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vendorModel.title ?? 'Restaurant',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey900,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Spacer(),
                  _buildBottomInfoRow(vendorModel),
                ],
              ),
            ),
            if (isClosed) _buildClosedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CLOSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: AppThemeData.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusBadge(VendorModel vendorModel) {
    final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.9)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.circle : Icons.circle_outlined,
            size: 6,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontFamily: AppThemeData.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoRow(VendorModel vendorModel) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.star, size: 12, color: AppThemeData.primary300),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount?.toStringAsFixed(0) ?? '0'})",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (vendorModel.distance != null) ...[
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 10,
                  color: AppThemeData.grey400,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    "${(vendorModel.distance ?? 0).toStringAsFixed(1)} km",
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.grey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWhatsAppFAB() {
    return Consumer3<CartProvider, CartControllerProvider, HomeProvider>(
      builder:
          (context, cartProvider, cartControllerProvider, homeProvider, _) {
            final showMiniCart = HomeProvider.cartItem.isNotEmpty;
            return Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 0,
                  child: const MiniCartBar(),
                ),
                Positioned(
                  bottom: showMiniCart ? 100 : 16,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: _launchWhatsApp,
                    backgroundColor: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: SvgPicture.asset(
                        'assets/images/whatsapp.svg',
                        width: 44,
                        height: 44,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  Future<void> _launchWhatsApp() async {
    const String phoneNumber = '+919390579864';
    const String message = 'Hello! I need help with my order.';
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
        if (await canLaunchUrl(phoneUrl)) {
          await launchUrl(phoneUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
    }
  }
}

class AdvertisementHomeCard extends StatelessWidget {
  final AdvertisementModel model;
  final HomeProvider controller;

  const AdvertisementHomeCard({
    super.key,
    required this.controller,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return InkWell(
          onTap: () => _onAdvertisementTap(restaurantDetailsProvider),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: Responsive.width(70, context),
            decoration: BoxDecoration(
              color: AppThemeData.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildImageSection(), _buildContentSection()],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        model.type == 'restaurant_promotion'
            ? ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: NetworkImageWidget(
                  imageUrl: model.coverImage ?? '',
                  height: 135,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : VideoAdvWidget(
                url: model.video ?? '',
                height: 135,
                width: double.infinity,
              ),
        if (model.type != 'video_promotion' &&
            model.vendorId != null &&
            (model.showRating == true || model.showReview == true))
          Positioned(bottom: 8, right: 8, child: _buildRatingWidget()),
      ],
    );
  }

  Widget _buildRatingWidget() {
    return FutureBuilder(
      future: FireStoreUtils.getVendorById(model.vendorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            snapshot.data == null) {
          return const SizedBox();
        }

        final vendorModel = snapshot.data!;
        return Container(
          decoration: ShapeDecoration(
            color: AppThemeData.primary50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(120),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_star.svg",
                  colorFilter: ColorFilter.mode(
                    AppThemeData.primary300,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "${model.showRating == true ? Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString()) : ''} ${model.showReview == true ? '(${vendorModel.reviewsCount!.toStringAsFixed(0)})' : ''}",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppThemeData.primary300,
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (model.type == 'restaurant_promotion')
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NetworkImageWidget(
                imageUrl: model.profileImage ?? '',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title ?? '',
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  model.description ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Container(
            decoration: ShapeDecoration(
              color: AppThemeData.primary50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppThemeData.primary300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAdvertisementTap(
    RestaurantDetailsProvider restaurantDetailsProvider,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        model.vendorId!,
      );
      ShowToastDialog.closeLoader();

      if (vendorModel != null) {
        restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
        Get.to(() => const RestaurantDetailsScreen());
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to load restaurant details".tr);
    }
  }
}
