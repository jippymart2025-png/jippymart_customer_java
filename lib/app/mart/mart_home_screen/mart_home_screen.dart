// // import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
// // import 'package:jippymart_customer/app/mart/mart_home_screen/widget/grocery_component_widget.dart';
// // import 'package:jippymart_customer/app/mart/mart_home_screen/widget/mart_header_card.dart';
// // import 'package:jippymart_customer/app/mart/mart_home_screen/widget/mart_home_search_widget.dart';
// // import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
// // import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
// // import 'package:jippymart_customer/app/mart/widgets/playtime_product_card.dart';
// // import 'package:jippymart_customer/models/mart_category_model.dart';
// // import 'package:jippymart_customer/models/mart_item_model.dart';
// // import 'package:jippymart_customer/themes/mart_theme.dart';
// // import 'package:jippymart_customer/utils/network_image_widget.dart';
// // import 'package:jippymart_customer/utils/utils/color_const.dart';
// // import 'package:jippymart_customer/widgets/reusable_banner_widget.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:get/get.dart';
// // import 'package:provider/provider.dart';
// // import 'package:url_launcher/url_launcher.dart';
// //
// // class MartHomeScreen extends StatelessWidget {
// //   const MartHomeScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final screenWidth = MediaQuery.of(context).size.width;
// //     Size size = MediaQuery.of(context).size;
// //     return Theme(
// //       data: MartTheme.theme,
// //       child: Scaffold(
// //         backgroundColor: Colors.transparent,
// //         body: Consumer<MartProvider>(
// //           builder: (context, controller, _) {
// //             // WidgetsBinding.instance.addPostFrameCallback((_) {
// //             //   if (controller.featuredCategories.isEmpty &&
// //             //       !controller.isCategoryLoading &&
// //             //       !controller.isHomepageCategoriesLoaded) {
// //             //     controller.loadHomepageCategoriesStreaming(limit: 6);
// //             //   }
// //             //   if (controller.featuredItems.isEmpty &&
// //             //       !controller.isProductLoading) {
// //             //     controller.loadFeaturedItemsStreaming();
// //             //   }
// //             //   if (controller.trendingItems.isEmpty &&
// //             //       !controller.isTrendingLoading) {
// //             //     controller.loadTrendingItemsStreaming();
// //             //   }
// //             //   if (controller.subcategories.isEmpty &&
// //             //       !controller.isSubcategoryLoading) {
// //             //     if (controller.featuredCategories.isNotEmpty) {
// //             //       final mainCategory = controller.featuredCategories[0];
// //             //       controller.loadSubcategoriesStreaming(mainCategory.id ?? '');
// //             //     }
// //             //   }
// //             // });
// //             return SingleChildScrollView(
// //               child: Column(
// //                 children: [
// //                   Stack(
// //                     children: [
// //                       Container(
// //                         height: 430,
// //                         width: double.infinity,
// //                         decoration: BoxDecoration(
// //                           color: ColorConst.greenLight,
// //                           borderRadius: BorderRadius.only(
// //                             bottomLeft: Radius.circular(26),
// //                             bottomRight: Radius.circular(26),
// //                           ), // set your desired radius
// //                         ),
// //                       ),
// //                       RefreshIndicator(
// //                         onRefresh: controller.refreshData,
// //                         child: Column(
// //                           children: [
// //                             MartHeaderCard(screenWidth: screenWidth),
// //                             SizedBox(height: 10),
// //                             homeSearchWidget(),
// //                             SizedBox(height: 10),
// //                             controller.martTopBanners.isNotEmpty
// //                                 ? Column(
// //                                     children: [
// //                                       Padding(
// //                                         padding: const EdgeInsets.only(
// //                                           left: 10.0,
// //                                           right: 10,
// //                                           top: 10,
// //                                         ),
// //                                         child: ReusableBannerWidget(
// //                                           banners: controller.martTopBanners,
// //                                           pageController: controller
// //                                               .martTopBannerController,
// //                                           currentPage:
// //                                               controller.currentTopBannerPage,
// //                                           height: 150,
// //                                           onPanStart: () =>
// //                                               controller.stopMartBannerTimer(),
// //                                           onPanEnd: () =>
// //                                               controller.startMartBannerTimer(),
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   )
// //                                 : const SizedBox.shrink(),
// //                             SizedBox(height: 10),
// //                             groceryComponent(size),
// //                             MartDynamicSectionsEnhanced(
// //                               screenWidth: screenWidth,
// //                             ),
// //                             SizedBox(height: 25),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         ),
// //         floatingActionButton: GestureDetector(
// //           onTap: () async {
// //             const String phoneNumber = '+919390579864';
// //             const String message =
// //                 'Hello! I need help with my JippyMart order.';
// //             final Uri whatsappUrl = Uri.parse(
// //               'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
// //             );
// //             try {
// //               if (await canLaunchUrl(whatsappUrl)) {
// //                 await launchUrl(
// //                   whatsappUrl,
// //                   mode: LaunchMode.externalApplication,
// //                 );
// //               } else {
// //                 // Fallback to regular phone call if WhatsApp is not available
// //                 final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
// //                 if (await canLaunchUrl(phoneUrl)) {
// //                   await launchUrl(
// //                     phoneUrl,
// //                     mode: LaunchMode.externalApplication,
// //                   );
// //                 }
// //               }
// //             } catch (e) {
// //               print('Error launching WhatsApp: $e');
// //             }
// //           },
// //           child: Container(
// //             width: 56,
// //             height: 56,
// //             decoration: BoxDecoration(
// //               color: Colors.green, // WhatsApp green color
// //               shape: BoxShape.circle,
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.2),
// //                   blurRadius: 8,
// //                   offset: const Offset(0, 4),
// //                 ),
// //               ],
// //             ),
// //             child: Padding(
// //               padding: const EdgeInsets.all(0.0),
// //               child: SvgPicture.asset(
// //                 'assets/images/whatsapp.svg',
// //                 width: 24,
// //                 height: 24,
// //                 colorFilter: const ColorFilter.mode(
// //                   Colors.white,
// //                   BlendMode.srcIn,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class MartSpotlightSelections extends StatelessWidget {
// //   final double screenWidth;
// //
// //   const MartSpotlightSelections({super.key, required this.screenWidth});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 413,
// //       height: 263,
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF00998a), // Rectangle 5 background
// //       ),
// //       child: Stack(
// //         children: [
// //           // Face In Clouds icon
// //           Positioned(
// //             left: 169,
// //             top: 19,
// //             child: SizedBox(
// //               width: 67,
// //               height: 67,
// //               child: Image.asset(
// //                 'assets/images/FaceInClouds.gif',
// //                 width: 67,
// //                 height: 67,
// //                 fit: BoxFit.contain,
// //                 errorBuilder: (context, error, stackTrace) {
// //                   return Container(
// //                     width: 67,
// //                     height: 67,
// //                     decoration: BoxDecoration(
// //                       color: Colors.amber,
// //                       borderRadius: BorderRadius.circular(33.5),
// //                     ),
// //                     child: const Icon(
// //                       Icons.star,
// //                       color: Colors.white,
// //                       size: 40,
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //
// //           // Spotlight Selections title
// //           Positioned(
// //             left: 35,
// //             top: 86,
// //             child: const Text(
// //               'Spotlight Selections',
// //               style: TextStyle(
// //                 fontFamily: 'Montserrat',
// //                 fontSize: 32,
// //                 fontWeight: FontWeight.w700,
// //                 height: 39 / 32,
// //                 color: Colors.white,
// //               ),
// //             ),
// //           ),
// //
// //           // Frame 40 - Horizontal scrollable container
// //           Positioned(
// //             left: 1,
// //             top: 150,
// //             child: SizedBox(
// //               width: 402,
// //               height: 92,
// //               child: Consumer<MartProvider>(
// //                 builder: (context, controller, _) {
// //                   if (controller.spotlightItems.isEmpty) {
// //                     return const Center(
// //                       child: Text(
// //                         'No spotlight items available',
// //                         style: TextStyle(color: Colors.white70),
// //                       ),
// //                     );
// //                   }
// //
// //                   return SingleChildScrollView(
// //                     scrollDirection: Axis.horizontal,
// //                     child: Row(
// //                       children: [
// //                         ...controller.spotlightItems.asMap().entries.map((
// //                           entry,
// //                         ) {
// //                           final index = entry.key;
// //                           final item = entry.value;
// //
// //                           return Row(
// //                             children: [
// //                               _SpotlightCard(
// //                                 title: item['title'] ?? 'Category',
// //                                 discount: item['discount'] ?? 'Up to 50% OFF',
// //                               ),
// //                               // Add spacing between cards (except for the last one)
// //                               if (index < controller.spotlightItems.length - 1)
// //                                 const SizedBox(width: 12),
// //                             ],
// //                           );
// //                         }),
// //                       ],
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // Spotlight Card widget matching CSS specifications
// // class _SpotlightCard extends StatelessWidget {
// //   final String title;
// //   final String discount;
// //
// //   const _SpotlightCard({required this.title, required this.discount});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: () {
// //         // Show coming soon message
// //         Get.snackbar(
// //           'Coming Soon',
// //           'This feature is under development',
// //           snackPosition: SnackPosition.BOTTOM,
// //         );
// //       },
// //       child: SizedBox(
// //         width: 88,
// //         height: 92,
// //         child: Stack(
// //           children: [
// //             // Rectangle background (white card)
// //             Positioned(
// //               left: 0,
// //               top: 0,
// //               child: Container(
// //                 width: 88,
// //                 height: 92,
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFFFAF9EE),
// //                   borderRadius: BorderRadius.circular(18),
// //                 ),
// //               ),
// //             ),
// //
// //             // Category title - positioned based on CSS
// //             Positioned(
// //               left: 4,
// //               top: 7,
// //               child: SizedBox(
// //                 width: 80,
// //                 height: 24,
// //                 child: Text(
// //                   title,
// //                   style: const TextStyle(
// //                     fontFamily: 'Montserrat',
// //                     fontSize: 10,
// //                     fontWeight: FontWeight.w700,
// //                     height: 12 / 10,
// //                     color: Color(0xFF000000),
// //                   ),
// //                   maxLines: 2,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ),
// //             ),
// //
// //             // Gradient offer bar - positioned based on CSS
// //             Positioned(
// //               left: 4,
// //               top: 73,
// //               child: Container(
// //                 width: 80,
// //                 height: 15,
// //                 decoration: const BoxDecoration(
// //                   gradient: LinearGradient(
// //                     begin: Alignment.centerLeft,
// //                     end: Alignment.centerRight,
// //                     colors: [
// //                       Color(0xFF595BD4), // #595BD4
// //                       Color(0xFF9140D8), // #9140D8
// //                     ],
// //                   ),
// //                   borderRadius: BorderRadius.only(
// //                     bottomLeft: Radius.circular(18),
// //                     bottomRight: Radius.circular(18),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //             // Discount text - positioned based on CSS
// //             Positioned(
// //               left: 12,
// //               top: 76,
// //               child: Text(
// //                 discount,
// //                 style: const TextStyle(
// //                   fontFamily: 'Montserrat',
// //                   fontSize: 7,
// //                   fontWeight: FontWeight.w700,
// //                   height: 9 / 7,
// //                   color: Colors.white,
// //                 ),
// //               ),
// //             ),
// //
// //             // Placeholder icon in center (Rectangle with background url)
// //             Positioned(
// //               left: 30, // Fixed position for all cards
// //               top: 36, // 39.13% of 92px ≈ 36px
// //               child: Container(
// //                 width: 28,
// //                 height: 28,
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF5D56F3),
// //                   borderRadius: BorderRadius.circular(14),
// //                 ),
// //                 child: const Icon(
// //                   Icons.shopping_basket,
// //                   color: Colors.white,
// //                   size: 16,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // Helper method for spotlight subcategories
// //
// // class _GroceryItem extends StatelessWidget {
// //   final String label;
// //   final String? imageUrl;
// //
// //   const _GroceryItem({required this.label, this.imageUrl});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: () {
// //         Get.snackbar(
// //           'Coming Soon',
// //           'This feature is under development',
// //           snackPosition: SnackPosition.BOTTOM,
// //         );
// //       },
// //       child: SizedBox(
// //         width: 87,
// //         height: 129,
// //         child: Stack(
// //           children: [
// //             Positioned(
// //               left: 0,
// //               top: 0,
// //               child: Container(
// //                 width: 87,
// //                 height: 91,
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFFECEAFD),
// //                   borderRadius: BorderRadius.circular(18),
// //                 ),
// //                 child: ClipRRect(
// //                   borderRadius: BorderRadius.circular(18),
// //                   child: imageUrl != null
// //                       ? NetworkImageWidget(
// //                           imageUrl: imageUrl!,
// //                           width: 87,
// //                           height: 91,
// //                           fit: BoxFit.cover,
// //                           errorWidget: Container(
// //                             decoration: BoxDecoration(
// //                               color: const Color(0xFFECEAFD),
// //                               borderRadius: BorderRadius.circular(18),
// //                             ),
// //                             child: const Icon(
// //                               Icons.image,
// //                               color: Color(0xFF5D56F3),
// //                               size: 30,
// //                             ),
// //                           ),
// //                         )
// //                       : Container(
// //                           decoration: BoxDecoration(
// //                             color: const Color(0xFFECEAFD),
// //                             borderRadius: BorderRadius.circular(18),
// //                           ),
// //                           child: const Icon(
// //                             Icons.image,
// //                             color: Color(0xFF5D56F3),
// //                             size: 30,
// //                           ),
// //                         ),
// //                 ),
// //               ),
// //             ),
// //
// //             // Text label
// //             Positioned(
// //               left: 9, // 24 - 15 (container left offset)
// //               top: 99, // 817 - 718 (top offset)
// //               child: SizedBox(
// //                 width: 70,
// //                 height: 30,
// //                 child: Text(
// //                   label,
// //                   style: const TextStyle(
// //                     fontFamily: 'Montserrat',
// //                     fontSize: 12,
// //                     fontWeight: FontWeight.w600,
// //                     height: 15 / 12,
// //                     // line-height: 15px
// //                     color: Color(0xFF000000),
// //                   ),
// //                   textAlign: TextAlign.center,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class MartGlowWellnessSection extends StatelessWidget {
// //   final double screenWidth;
// //
// //   const MartGlowWellnessSection({super.key, required this.screenWidth});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Section Title
// //           const Text(
// //             'GLOW & WELLNESS',
// //             style: TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.bold,
// //               color: Color(0xFF2D1B69),
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //           // Wellness Grid
// //           GridView.count(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             crossAxisCount: 4,
// //             crossAxisSpacing: 8,
// //             mainAxisSpacing: 12,
// //             childAspectRatio: 87 / 129,
// //             // Exact ratio from CSS
// //             children: [
// //               _GroceryItem(
// //                 label: 'Bath &\nBody',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Hair\nCare',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1522338140263-f46f5913618a?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Skincare',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Makeup',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Oral\nCare',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Grooming',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Baby\nCare',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Fragrances',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Protein and\nSupplements',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Feminine\nHygiene',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Sexual\nWellness',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Health and\nPharma',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class MartSnacksRefreshmentsSection extends StatelessWidget {
// //   final double screenWidth;
// //
// //   const MartSnacksRefreshmentsSection({super.key, required this.screenWidth});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Section Title
// //           const Text(
// //             'SNACKS & REFRESHMENTS',
// //             style: TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.bold,
// //               color: Color(0xFF2D1B69),
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //
// //           // Snacks Grid
// //           GridView.count(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             crossAxisCount: 4,
// //             crossAxisSpacing: 8,
// //             mainAxisSpacing: 12,
// //             childAspectRatio: 87 / 129,
// //             // Exact ratio from CSS
// //             children: [
// //               _GroceryItem(
// //                 label: 'Cold Drinks\nand Juices',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Ice Creams and\nFrozen Desserts',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Chips and\nNamkeens',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Chocolates',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Noodles Pasta\nVermicelli',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Frozen\nFood',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Sweets',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Paan\nCorner',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class MartEverydayLifeHomeSection extends StatelessWidget {
// //   final double screenWidth;
// //
// //   const MartEverydayLifeHomeSection({super.key, required this.screenWidth});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Section Title
// //           const Text(
// //             'EVERYDAY LIFE & HOME',
// //             style: TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.bold,
// //               color: Color(0xFF2D1B69),
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //
// //           // Everyday Life Grid
// //           GridView.count(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             crossAxisCount: 4,
// //             crossAxisSpacing: 8,
// //             mainAxisSpacing: 12,
// //             childAspectRatio: 87 / 129,
// //             // Exact ratio from CSS
// //             children: [
// //               _GroceryItem(
// //                 label: 'Home and\nFurnishing',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Kitchen and\nDining',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Cleaning\nEssentials',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Clothing',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Mobiles and\nElectronics',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Appliances',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Books and\nStationery',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Jewellery and\nAccessories',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Puja',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Toys and\nGames',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Sports and\nFitness',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //               _GroceryItem(
// //                 label: 'Pet\nSupplies',
// //                 imageUrl:
// //                     'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class MartLocalStoreSection extends StatelessWidget {
// //   final double screenWidth;
// //
// //   const MartLocalStoreSection({super.key, required this.screenWidth});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Section Title
// //           const Text(
// //             'LOCAL STORE',
// //             style: TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.bold,
// //               color: Color(0xFF2D1B69),
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //
// //           // Local Store Categories - Horizontal Scroll
// //           SizedBox(
// //             height: 140,
// //             child: ListView(
// //               scrollDirection: Axis.horizontal,
// //               padding: const EdgeInsets.symmetric(horizontal: 4),
// //               children: [
// //                 _LocalStoreItem(
// //                   label: 'Party Store',
// //                   color: const Color(0xFFD8D5FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Gourmet Store',
// //                   color: const Color(0xFFFFE4B5),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Puja Store',
// //                   color: const Color(0xFFFFE4E1),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Local Favourites',
// //                   color: const Color(0xFFFFE4B5),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Toys & Stationery',
// //                   color: const Color(0xFFFFE4E1),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Gifting Store',
// //                   color: const Color(0xFFE0E0FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Pet Store',
// //                   color: const Color(0xFFE8D7C6),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Health & Fitness',
// //                   color: const Color(0xFFD8D5FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Travel Store',
// //                   color: const Color(0xFFE0E0FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Electronics Store',
// //                   color: const Color(0xFFD8D5FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Fashion Store',
// //                   color: const Color(0xFFFFE4E1),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Beauty Store',
// //                   color: const Color(0xFFFFE4B5),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Sports Store',
// //                   color: const Color(0xFFE8D7C6),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Book Store',
// //                   color: const Color(0xFFD8D5FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Music Store',
// //                   color: const Color(0xFFE0E0FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Art & Craft',
// //                   color: const Color(0xFFFFE4B5),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Garden Store',
// //                   color: const Color(0xFFE8D7C6),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Auto Store',
// //                   color: const Color(0xFFD8D5FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Hardware Store',
// //                   color: const Color(0xFFE0E0FF),
// //                   screenWidth: screenWidth,
// //                 ),
// //                 _LocalStoreItem(
// //                   label: 'Pharmacy',
// //                   color: const Color(0xFFFFE4E1),
// //                   screenWidth: screenWidth,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _LocalStoreItem extends StatelessWidget {
// //   final String label;
// //   final Color color;
// //   final double screenWidth;
// //
// //   const _LocalStoreItem({
// //     required this.label,
// //     required this.color,
// //     required this.screenWidth,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final itemSize = 120.0; // Further reduced size to fit
// //
// //     return Container(
// //       width: itemSize + 12, // Add margin
// //       margin: const EdgeInsets.only(right: 2),
// //       child: Column(
// //         children: [
// //           Container(
// //             width: itemSize,
// //             height: itemSize,
// //             decoration: BoxDecoration(
// //               color: color,
// //               borderRadius: BorderRadius.circular(12),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.1),
// //                   blurRadius: 8,
// //                   offset: const Offset(0, 2),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             label,
// //             textAlign: TextAlign.center,
// //             style: const TextStyle(
// //               fontSize: 11,
// //               fontWeight: FontWeight.w600,
// //               color: Color(0xFF2D1B69),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // Helper function to parse color from hex string
// // Color _parseColor(String hexColor) {
// //   try {
// //     hexColor = hexColor.replaceAll('#', '');
// //     if (hexColor.length == 6) {
// //       hexColor = 'FF$hexColor'; // Add alpha channel
// //     }
// //     return Color(int.parse(hexColor, radix: 16));
// //   } catch (e) {
// //     return const Color(0xFFE8E4FF); // Default color
// //   }
// // }
// //
// // // Helper function to sanitize image URLs
// // // Enhanced version that uses controller methods
// // class MartDynamicSectionsEnhanced extends StatefulWidget {
// //   final double screenWidth;
// //
// //   const MartDynamicSectionsEnhanced({super.key, required this.screenWidth});
// //
// //   @override
// //   State<MartDynamicSectionsEnhanced> createState() =>
// //       _MartDynamicSectionsEnhancedState();
// // }
// //
// // class _MartDynamicSectionsEnhancedState
// //     extends State<MartDynamicSectionsEnhanced> {
// //   // bool _hasTriggeredLoading = false;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer2<MartProvider, CategoryDetailsProvider>(
// //       builder: (context, controller, categoryDetailsProvider, _) {
// //         // if (!_hasTriggeredLoading) {
// //         //   _hasTriggeredLoading = true;
// //         //   WidgetsBinding.instance.addPostFrameCallback((_) {
// //         //     controller.loadCategoryProductsForSections();
// //         //   });
// //         // }
// //         final categoryProducts = controller.categoryProductsMap;
// //         final uniqueCategories = controller.uniqueCategoryTitles;
// //         if (uniqueCategories.isEmpty) {
// //           return const SizedBox.shrink();
// //         }
// //         return Column(
// //           children: uniqueCategories.map((category) {
// //             return _buildCategorySection(
// //               context,
// //               controller,
// //               category,
// //               categoryProducts[category] ?? [],
// //             );
// //           }).toList(),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildCategorySection(
// //     BuildContext context,
// //     MartProvider controller,
// //     String categoryName,
// //     List<MartItemModel> products,
// //   ) {
// //     if (products.isEmpty) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.only(),
// //       child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Padding(
// //                 padding: const EdgeInsets.symmetric(
// //                   horizontal: 20,
// //                   vertical: 4,
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Expanded(
// //                       child: Text(
// //                         categoryName,
// //                         style: TextStyle(
// //                           fontFamily: 'Montserrat',
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w700,
// //                           color: Color(0xFF1A1A1A),
// //                           letterSpacing: -0.5,
// //                         ),
// //                         overflow: TextOverflow.ellipsis,
// //                         maxLines: 1,
// //                       ),
// //                     ),
// //                     const SizedBox(width: 8),
// //                     GestureDetector(
// //                       onTap: () {
// //                         final category = controller.martCategories.firstWhere(
// //                           (cat) => cat.title == categoryName,
// //                           orElse: () =>
// //                               MartCategoryModel(id: '', title: categoryName),
// //                         );
// //                         context.read<CategoryDetailsProvider>().initFunction(
// //                           categoryIds:
// //                               category.id ??
// //                               'category_${categoryName.toLowerCase().replaceAll(' ', '_')}',
// //                           categoryNames: categoryName,
// //                           sectionNames: 'category',
// //                         );
// //                         Get.to(() => MartCategoryDetailScreen());
// //                       },
// //                       child: Container(
// //                         decoration: BoxDecoration(
// //                           color: ColorConst.martPrimary.withOpacity(0.1),
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                         child: Padding(
// //                           padding: const EdgeInsets.symmetric(
// //                             horizontal: 12,
// //                             vertical: 6,
// //                           ),
// //                           child: Text(
// //                             'View All',
// //                             style: TextStyle(
// //                               fontFamily: 'Montserrat',
// //                               fontSize: 12,
// //                               fontWeight: FontWeight.w600,
// //                               color: ColorConst.martPrimary,
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               Padding(
// //                 padding: const EdgeInsets.only(left: 16),
// //                 child: SizedBox(
// //                   height: 215,
// //                   child: ListView.builder(
// //                     scrollDirection: Axis.horizontal,
// //                     itemCount: products.length,
// //                     itemBuilder: (context, index) {
// //                       final product = products[index];
// //                       return PlaytimeProductCard(
// //                         volume:
// //                             '${product.grams ?? 0}${_getVolumeUnit(product)}',
// //                         productName: product.name,
// //                         discount: '${_calculateDiscount(product)}% OFF',
// //                         currentPrice: '₹${product.disPrice ?? product.price}',
// //                         originalPrice: '₹${product.price}',
// //                         screenWidth: widget.screenWidth,
// //                         imageUrl: product.photo,
// //                         product: product,
// //                       );
// //                     },
// //                   ),
// //                 ),
// //               ),
// //
// //               const SizedBox(height: 24), // Add spacing between sections
// //             ],
// //           ),
// //         );
// //   }
// //
// //   String _getVolumeUnit(MartItemModel product) {
// //     if (product.grams != null && product.grams! > 0) {
// //       return 'g';
// //     }
// //     return 'g'; // Default to grams
// //   }
// //
// //   int _calculateDiscount(MartItemModel product) {
// //     if (product.disPrice != null && product.price > product.disPrice!) {
// //       return ((product.price - product.disPrice!) / product.price * 100)
// //           .round();
// //     }
// //     return 0;
// //   }
// // }
// //
// // // Dynamic Sections Widget
// // class MartDynamicSections extends StatefulWidget {
// //   final double screenWidth;
// //
// //   const MartDynamicSections({super.key, required this.screenWidth});
// //
// //   @override
// //   State<MartDynamicSections> createState() => _MartDynamicSectionsState();
// // }
// //
// // class _MartDynamicSectionsState extends State<MartDynamicSections> {
// //   bool _hasTriggeredLoading = false;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<MartProvider>(
// //       builder: (context, controller, _) {
// //         // Trigger sections loading only once to prevent blinking
// //         if (!_hasTriggeredLoading && controller.availableSections.isEmpty) {
// //           _hasTriggeredLoading = true;
// //           WidgetsBinding.instance.addPostFrameCallback((_) {
// //             controller.loadSectionsImmediately();
// //             Future.delayed(const Duration(seconds: 2), () {
// //               if (controller.availableSections.isEmpty) {
// //                 controller.addTestSections();
// //               }
// //             });
// //           });
// //         }
// //         if (controller.availableSections.isEmpty) {
// //           return const SizedBox.shrink();
// //         }
// //         return Column(
// //           children: controller.availableSections.map((section) {
// //             return _buildSection(context, controller, section);
// //           }).toList(),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildSection(
// //     BuildContext context,
// //     MartProvider controller,
// //     String sectionName,
// //   ) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.only(
// //         // left: 16,
// //         // right: 16,
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(
// //                   sectionName,
// //                   style: TextStyle(
// //                     fontFamily: 'Montserrat',
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w700,
// //                     color: Color(0xFF1A1A1A),
// //                     letterSpacing: -0.5,
// //                   ),
// //                 ),
// //                 const SizedBox(width: 8),
// //                 GestureDetector(
// //                   onTap: () {
// //                     context.read<CategoryDetailsProvider>().initFunction(
// //                           categoryIds:
// //                               'section_${sectionName.toLowerCase().replaceAll(' ', '_')}',
// //                           categoryNames: sectionName,
// //                           sectionNames: 'section',
// //                           initialFilters: sectionName,
// //                         );
// //                     Get.to(() => MartCategoryDetailScreen());
// //                   },
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       color: ColorConst.martPrimary.withOpacity(0.1),
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     child: Padding(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 12,
// //                         vertical: 6,
// //                       ),
// //                       child: Text(
// //                         'View All',
// //                         style: TextStyle(
// //                           fontFamily: 'Montserrat',
// //                           fontSize: 12,
// //                           fontWeight: FontWeight.w600,
// //                           color: ColorConst.martPrimary,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           // Row(
// //           //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           //   children: [
// //           //     Expanded(
// //           //       child: Text(
// //           //         sectionName, // Use the section name from Firebase
// //           //         style: TextStyle(
// //           //           fontSize: widget.screenWidth < 360 ? 14 : 16,
// //           //           fontWeight: FontWeight.bold,
// //           //           color: const Color(0xFF2D1B69),
// //           //         ),
// //           //         overflow: TextOverflow.ellipsis,
// //           //         maxLines: 1,
// //           //       ),
// //           //     ),
// //           //     const SizedBox(width: 8),
// //           //     GestureDetector(
// //           //       onTap: () {
// //           //         // Navigate to category detail screen with section filter
// //           //         print(
// //           //             '[MART DYNAMIC SECTIONS] 🔗 Navigating to section: $sectionName');
// //           //         Get.to(() => MartCategoryDetailScreen(), arguments: {
// //           //           'categoryId':
// //           //               'section_${sectionName.toLowerCase().replaceAll(' ', '_')}',
// //           //           'categoryName': sectionName,
// //           //           'initialFilter': 'section',
// //           //           'sectionName': sectionName, // Pass the actual section name
// //           //         });
// //           //       },
// //           //       child: const Text(
// //           //         'See All >',
// //           //         style: TextStyle(
// //           //           fontSize: 16,
// //           //           color: Colors.blue,
// //           //           fontWeight: FontWeight.w600,
// //           //         ),
// //           //       ),
// //           //     ),
// //           //   ],
// //           // ),
// //           // const SizedBox(height: 16),
// //           // Horizontal Scroll of Products using PlaytimeProductCard
// //           Padding(
// //             padding: const EdgeInsets.only(left: 16),
// //             child: Consumer<MartProvider>(
// //               builder: (context, controller, _) {
// //                 // Get products for this section from Firebase
// //                 final sectionProducts = controller.getProductsForSection(
// //                   sectionName,
// //                 );
// //                 // If no products available, don't show anything (sections will appear as products load)
// //                 if (sectionProducts.isEmpty) {
// //                   return const SizedBox.shrink();
// //                 }
// //                 return SizedBox(
// //                   height: 215,
// //                   child: ListView.builder(
// //                     scrollDirection: Axis.horizontal,
// //                     itemCount: sectionProducts.length,
// //                     itemBuilder: (context, index) {
// //                       final product = sectionProducts[index];
// //                       return PlaytimeProductCard(
// //                         volume: '${product.grams ?? 0}g',
// //                         productName: product.name,
// //                         discount: '${_calculateDiscount(product)}% OFF',
// //                         currentPrice: '₹${product.disPrice ?? product.price}',
// //                         originalPrice: '₹${product.price}',
// //                         screenWidth: widget.screenWidth,
// //                         imageUrl: product.photo,
// //                         product:
// //                             product, // Pass the product model for navigation
// //                       );
// //                     },
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   int _calculateDiscount(MartItemModel product) {
// //     if (product.disPrice != null && product.price > product.disPrice!) {
// //       return ((product.price - product.disPrice!) / product.price * 100)
// //           .round();
// //     }
// //     return 0;
// //   }
// // }
// //
// // Widget searchWidgetMain() {
// //   /// Get appropriate icon for category based on name
// //
// //   return Container(
// //     // width: 412,
// //     // height: 190,
// //     color: Colors.transparent,
// //
// //     child: Column(
// //       children: [
// //         SizedBox(height: 16),
// //
// //         // Group 262 - Search Bar
// //       ],
// //     ),
// //   );
// // }
// //
// // // Helper method for user initials (keeping this one as it's still used)
// //
// // // Dynamic Categories Section - Replaces dummy data sections
// // class MartDynamicCategoriesSection extends StatelessWidget {
// //   final double screenWidth;
// //
// //   const MartDynamicCategoriesSection({super.key, required this.screenWidth});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<MartProvider>(
// //       builder: (context, controller, _) {
// //         if (controller.isCategoryLoading) {
// //           return Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text(
// //                   'Categories',
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                     color: Color(0xFF2D1B69),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 GridView.count(
// //                   shrinkWrap: true,
// //                   physics: const NeverScrollableScrollPhysics(),
// //                   crossAxisCount: 4,
// //                   crossAxisSpacing: 12,
// //                   mainAxisSpacing: 16,
// //                   childAspectRatio: 0.75,
// //                   // Fixed overflow issue
// //                   children: List.generate(
// //                     8,
// //                     (index) => Container(
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey[200],
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: const Center(child: CircularProgressIndicator()),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           );
// //         }
// //
// //         if (controller.featuredCategories.isEmpty) {
// //           return Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text(
// //                   'Categories',
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                     color: Color(0xFF2D1B69),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 const Center(
// //                   child: Text(
// //                     'No categories available',
// //                     style: TextStyle(color: Colors.grey, fontSize: 16),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           );
// //         }
// //
// //         return Consumer<CategoryDetailsProvider>(
// //           builder: (context, categoryDetailsProvider, _) {
// //             return Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   // Section Title
// //                   const Text(
// //                     'Categories',
// //                     style: TextStyle(
// //                       fontSize: 20,
// //                       fontWeight: FontWeight.bold,
// //                       color: Color(0xFF2D1B69),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //
// //                   // Dynamic Categories Grid
// //                   GridView.count(
// //                     shrinkWrap: true,
// //                     physics: const NeverScrollableScrollPhysics(),
// //                     crossAxisCount: 4,
// //                     crossAxisSpacing: 12,
// //                     mainAxisSpacing: 16,
// //                     childAspectRatio: 0.75,
// //                     // Fixed overflow issue
// //                     children: controller.featuredCategories
// //                         .map(
// //                           (category) => _DynamicCategoryItem(
// //                             category: category,
// //                             onTap: () {
// //                               categoryDetailsProvider.initFunction(
// //                                 categoryIds: category.id,
// //                                 categoryNames: category.title,
// //                               );
// //                               Get.to(
// //                                 () => const MartCategoryDetailScreen(),
// //                                 arguments: {
// //                                   'categoryId': category.id,
// //                                   'categoryName': category.title,
// //                                 },
// //                               );
// //                             },
// //                           ),
// //                         )
// //                         .toList(),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // class _DynamicCategoryItem extends StatelessWidget {
// //   final MartCategoryModel category;
// //   final VoidCallback? onTap;
// //
// //   const _DynamicCategoryItem({required this.category, this.onTap});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(12),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withOpacity(0.1),
// //               blurRadius: 4,
// //               offset: const Offset(0, 2),
// //             ),
// //           ],
// //         ),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             // Category Image or Icon
// //             Expanded(
// //               flex: 3,
// //               child: Container(
// //                 width: double.infinity,
// //                 margin: const EdgeInsets.all(8),
// //                 decoration: BoxDecoration(
// //                   borderRadius: BorderRadius.circular(8),
// //                   color: _parseColor(category.backgroundColor ?? '#E8E4FF'),
// //                 ),
// //                 child: category.photo != null && category.photo!.isNotEmpty
// //                     ? ClipRRect(
// //                         borderRadius: BorderRadius.circular(8),
// //                         child: NetworkImageWidget(
// //                           imageUrl: category.photo!,
// //                           width: double.infinity,
// //                           height: double.infinity,
// //                           fit: BoxFit.cover,
// //                           errorWidget: _getCategoryIcon(category.title ?? ''),
// //                         ),
// //                       )
// //                     : _getCategoryIcon(category.title ?? ''),
// //               ),
// //             ),
// //
// //             // Category Name
// //             Expanded(
// //               flex: 2,
// //               child: Container(
// //                 width: double.infinity,
// //                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
// //                 child: Text(
// //                   category.title ?? 'Unknown',
// //                   style: const TextStyle(
// //                     fontSize: 11,
// //                     fontWeight: FontWeight.w600,
// //                     color: Color(0xFF2D1B69),
// //                   ),
// //                   textAlign: TextAlign.center,
// //                   maxLines: 2,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _getCategoryIcon(String categoryName) {
// //     IconData icon;
// //     Color color;
// //
// //     final name = categoryName.toLowerCase();
// //
// //     if (name.contains('grocery') ||
// //         name.contains('vegetable') ||
// //         name.contains('fruit')) {
// //       icon = Icons.shopping_basket;
// //       color = Colors.green;
// //     } else if (name.contains('dairy') ||
// //         name.contains('milk') ||
// //         name.contains('bread')) {
// //       icon = Icons.egg;
// //       color = Colors.orange;
// //     } else if (name.contains('medicine') || name.contains('health')) {
// //       icon = Icons.local_pharmacy;
// //       color = Colors.red;
// //     } else if (name.contains('pet')) {
// //       icon = Icons.pets;
// //       color = Colors.brown;
// //     } else if (name.contains('electronics') || name.contains('mobile')) {
// //       icon = Icons.phone_android;
// //       color = Colors.blue;
// //     } else if (name.contains('clothing') || name.contains('fashion')) {
// //       icon = Icons.checkroom;
// //       color = Colors.purple;
// //     } else if (name.contains('home') || name.contains('furniture')) {
// //       icon = Icons.home;
// //       color = Colors.indigo;
// //     } else if (name.contains('sports') || name.contains('fitness')) {
// //       icon = Icons.sports_soccer;
// //       color = Colors.teal;
// //     } else {
// //       icon = Icons.category;
// //       color = Colors.grey;
// //     }
// //
// //     return Icon(icon, size: 32, color: color);
// //   }
// // }
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
// import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
// import 'package:jippymart_customer/app/mart/mart_home_screen/widget/mart_header_card.dart';
// import 'package:jippymart_customer/models/cart_product_model.dart';
// import 'package:jippymart_customer/models/mart_item_model.dart';
// import 'package:jippymart_customer/services/cart_provider.dart';
// import 'package:jippymart_customer/themes/custom_dialog_box.dart';
// import 'package:jippymart_customer/themes/mart_theme.dart';
// import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
// import 'package:jippymart_customer/utils/utils/color_const.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import '../../search_screen/search_screen.dart';
// import '../mart_search_screen.dart';
//
// String _martVendorId(MartItemModel product, MartProvider mart) {
//   return 'mart_${product.vendorID ?? mart.selectedVendorId}';
// }
//
// CartProductModel _martCartLine(
//   MartItemModel product,
//   MartProvider mart, {
//   int quantity = 1,
// }) {
//   return CartProductModel(
//     id: product.id,
//     name: product.name,
//     photo: product.photo,
//     price: product.price.toString(),
//     discountPrice: product.price.toString(),
//     vendorID: _martVendorId(product, mart),
//     vendorName: 'Jippy Mart',
//     categoryId: product.categoryID,
//     quantity: quantity,
//     extrasPrice: '0',
//     extras: [],
//     variantInfo: null,
//     promoId: null,
//   );
// }
//
// int _martQtyInCart(
//   List<CartProductModel> items,
//   MartItemModel product,
//   String martVendorId,
// ) {
//   final pid = product.id;
//   if (pid == null || pid.isEmpty) return 0;
//   for (final item in items) {
//     if (item.vendorID != martVendorId) continue;
//     final iid = item.id;
//     if (iid == null || iid.isEmpty) continue;
//     if (iid == pid || iid.startsWith('$pid~')) {
//       return item.quantity ?? 0;
//     }
//   }
//   return 0;
// }
//
// Future<void> _handleMartIncrement(
//   BuildContext context,
//   MartItemModel product, {
//   bool showSnack = false,
// }) async {
//   final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//   if (!isLoggedIn) {
//     if (!context.mounted) return;
//     _showMartLoginDialog(context);
//     return;
//   }
//
//   try {
//     final martController = Provider.of<MartProvider>(context, listen: false);
//     final cartControllerProvider = Provider.of<CartControllerProvider>(
//       context,
//       listen: false,
//     );
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     final cartProduct = _martCartLine(product, martController);
//
//     final ok = await cartControllerProvider.addToCart(
//       cartProductModel: cartProduct,
//       isIncrement: true,
//       quantity: 1,
//     );
//     await cartProvider.initCart();
//     if (!context.mounted) return;
//     if (ok) {
//       HapticFeedback.lightImpact();
//       if (showSnack) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${product.name} added to cart'),
//             behavior: SnackBarBehavior.floating,
//             duration: const Duration(seconds: 2),
//             margin: const EdgeInsets.all(12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//     }
//   } catch (_) {
//     if (!context.mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Could not add to cart'),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(12),
//       ),
//     );
//   }
// }
//
// Future<void> _handleMartDecrement(
//   BuildContext context,
//   MartItemModel product,
//   int cartQuantity,
// ) async {
//   if (cartQuantity <= 0) return;
//   final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//   if (!isLoggedIn) {
//     if (!context.mounted) return;
//     _showMartLoginDialog(context);
//     return;
//   }
//
//   try {
//     final martController = Provider.of<MartProvider>(context, listen: false);
//     final cartControllerProvider = Provider.of<CartControllerProvider>(
//       context,
//       listen: false,
//     );
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//
//     final cartProduct = _martCartLine(
//       product,
//       martController,
//       quantity: cartQuantity,
//     );
//     final nextQty = cartQuantity > 1 ? cartQuantity - 1 : 0;
//     await cartControllerProvider.addToCart(
//       cartProductModel: cartProduct,
//       isIncrement: false,
//       quantity: nextQty,
//     );
//     await cartProvider.initCart();
//     if (context.mounted) HapticFeedback.selectionClick();
//   } catch (_) {
//     if (!context.mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Could not update cart'),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(12),
//       ),
//     );
//   }
// }
//
// void _showMartLoginDialog(BuildContext context) {
//   showDialog<void>(
//     context: context,
//     builder: (ctx) => CustomDialogBox(
//       title: 'Login Required'.tr,
//       descriptions:
//           'Please login to add items to your cart and continue shopping.'.tr,
//       positiveString: 'Login'.tr,
//       negativeString: 'Cancel'.tr,
//       positiveClick: () {
//         Get.back();
//         Get.to(() => PhoneNumberScreen());
//       },
//       negativeClick: () => Get.back(),
//       img: Image.asset('assets/images/ic_launcher.png', height: 50, width: 50),
//     ),
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // _RS  — one source of truth for every dimension on screen
// // ─────────────────────────────────────────────────────────────────────────────
// class _RS {
//   final double sw; // screen width
//   final double sh; // screen height
//
//   const _RS({required this.sw, required this.sh});
//
//   // breakpoints
//   bool get isSmall => sw < 360;
//
//   bool get isLarge => sw >= 600;
//
//   // ── grid (match restaurant ProductListView — restauant_product_list_view) ──
//   int get gridCols {
//     if (sw >= 600) return 3;
//     return 2;
//   }
//
//   double get gridSpacing => isSmall ? 8.0 : 10.0;
//
//   double get gridAspectRatio {
//     if (sw >= 600) return 0.78;
//     if (sw < 360) return 0.80;
//     return 0.80;
//   }
//
//   // ── layout ────────────────────────────────────────────────────
//   double get hPad => isSmall ? 10.0 : (isLarge ? 16.0 : 12.0);
//
//   // ── header ────────────────────────────────────────────────────
//   // height grows to fit: addr row + search bar + padding
//   // search bar is 36 px scaled; addr row ~44 px; tabs ~34 px
//   double get headerRadius => isSmall ? 16.0 : 20.0;
//
//   // ── search bar ────────────────────────────────────────────────
//   double get searchBarH => isSmall ? 32.0 : (isLarge ? 40.0 : 36.0);
//
//   double get searchIconSize => isSmall ? 13.0 : (isLarge ? 16.0 : 14.0);
//
//   double get searchFontSize => isSmall ? 11.0 : (isLarge ? 14.0 : 12.0);
//
//   double get searchRadius => isSmall ? 8.0 : (isLarge ? 12.0 : 10.0);
//
//   // ── section label ─────────────────────────────────────────────
//   double get sectionFontSize => isSmall ? 14.0 : (isLarge ? 16.0 : 16.0);
//
//   // ── card image ────────────────────────────────────────────────
//   // image height = card width × ratio  (card width derived from screen)
//   double get cardWidth {
//     final totalGap = hPad * 2 + gridSpacing * (gridCols - 1);
//     return (sw - totalGap) / gridCols;
//   }
//
//   double get imgHeight => cardWidth * 0.70;
//
//   // ── card text ─────────────────────────────────────────────────
//   double get nameFontSize => isSmall ? 11.0 : (isLarge ? 13.0 : 12.0);
//
//   double get priceFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);
//
//   /// Tight gap under product name before price row (no promo line / Spacer above price)
//   double get nameToPriceGap => isSmall ? 3.0 : 4.0;
//
//   // ── card buttons / qty stepper (compact, still tappable) ───────
//   double get addStepperHeight => isSmall ? 28.0 : (isLarge ? 34.0 : 30.0);
//
//   double get stepperBtnWidth => isSmall ? 30.0 : (isLarge ? 36.0 : 32.0);
//
//   double get addPillMinWidth => isSmall ? 64.0 : (isLarge ? 78.0 : 70.0);
//
//   double get addPillHPad => isSmall ? 8.0 : (isLarge ? 12.0 : 10.0);
//
//   double get stepperIconSize => isSmall ? 16.0 : (isLarge ? 19.0 : 17.0);
//
//   double get addLabelFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);
//
//   double get qtyCountFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);
//
//   double get qtyMidHPad => isSmall ? 4.0 : (isLarge ? 8.0 : 6.0);
//
//   double get shareBtnSize => isSmall ? 22.0 : (isLarge ? 27.0 : 24.0);
//
//   double get shareIconSize => isSmall ? 11.0 : (isLarge ? 14.0 : 12.0);
//
//   double get overlayPos => isSmall ? 5.0 : 6.0;
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // MartHomeScreen
// // ─────────────────────────────────────────────────────────────────────────────
// class MartHomeScreen extends StatefulWidget {
//   const MartHomeScreen({super.key});
//
//   @override
//   State<MartHomeScreen> createState() => _MartHomeScreenState();
// }
//
// class _MartHomeScreenState extends State<MartHomeScreen> {
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//   }
//
//   @override
//   void dispose() {
//     _scrollController
//       ..removeListener(_onScroll)
//       ..dispose();
//     super.dispose();
//   }
//
//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 300) {
//       context.read<MartProvider>().loadNextPage();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final rs = _RS(sw: size.width, sh: size.height);
//
//     return Theme(
//       data: MartTheme.theme,
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: Consumer<MartProvider>(
//           builder: (context, controller, _) {
//             return RefreshIndicator(
//               onRefresh: controller.refreshData,
//               child: CustomScrollView(
//                 controller: _scrollController,
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 slivers: [
//                   // ── Header (addr + search) ───────────────────────
//                   SliverToBoxAdapter(
//                     child: _MartHeader(rs: rs, screenWidth: size.width),
//                   ),
//
//                   // ── "All Products" label ─────────────────────────
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(rs.hPad, 4, rs.hPad, 4),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'All Products',
//                             style: TextStyle(
//                               fontSize: rs.sectionFontSize,
//                               fontWeight: FontWeight.w700,
//                               color: const Color(0xFF1A1A1A),
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () {},
//                             child: Text(
//                               'See all',
//                               style: TextStyle(
//                                 fontSize: rs.sectionFontSize - 1,
//                                 fontWeight: FontWeight.w600,
//                                 color: ColorConst.greenLight,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   // ── Products grid ────────────────────────────────
//                   _ProductGrid(rs: rs),
//
//                   // ── Pagination footer ────────────────────────────
//                   SliverToBoxAdapter(
//                     child: controller.isPaginating
//                         ? const Padding(
//                             padding: EdgeInsets.symmetric(vertical: 14),
//                             child: Center(
//                               child: SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                             ),
//                           )
//                         : const SizedBox(height: 72),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Header  — green bg, MartHeaderCard (tabs + address), then search bar
// // ─────────────────────────────────────────────────────────────────────────────
// class _MartHeader extends StatelessWidget {
//   final _RS rs;
//   final double screenWidth;
//
//   const _MartHeader({required this.rs, required this.screenWidth});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: ColorConst.greenLight,
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(rs.headerRadius),
//           bottomRight: Radius.circular(rs.headerRadius),
//         ),
//       ),
//       // Let content size itself — no fixed height
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Tabs + address from existing widget
//           MartHeaderCard(screenWidth: screenWidth),
//
//           // Search bar pinned inside the green header
//           Padding(
//             padding: EdgeInsets.fromLTRB(rs.hPad, 0, rs.hPad, 8),
//             child: MartHomeSearchWidget(rs: rs),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // MartHomeSearchWidget  (replaces your existing file or inline here)
// // ─────────────────────────────────────────────────────────────────────────────
// class MartHomeSearchWidget extends StatelessWidget {
//   final _RS rs;
//
//   const MartHomeSearchWidget({super.key, required this.rs});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         // Navigate to full search screen
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => MartSearchScreen()),
//         );
//       },
//       child: Container(
//         height: rs.searchBarH,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(rs.searchRadius),
//         ),
//         padding: EdgeInsets.symmetric(horizontal: rs.hPad * 0.8),
//         child: Row(
//           children: [
//             Icon(
//               Icons.search_rounded,
//               size: rs.searchIconSize + 2,
//               color: Colors.grey.shade400,
//             ),
//             SizedBox(width: rs.hPad * 0.5),
//             Expanded(
//               child: Text(
//                 'Search groceries, snacks…',
//                 style: TextStyle(
//                   fontSize: rs.searchFontSize,
//                   color: Colors.grey.shade400,
//                   fontWeight: FontWeight.w400,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Grid
// // ─────────────────────────────────────────────────────────────────────────────
// class _ProductGrid extends StatelessWidget {
//   final _RS rs;
//
//   const _ProductGrid({required this.rs});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MartProvider>(
//       builder: (context, controller, _) {
//         final products = controller.pagedProducts;
//
//         if (products.isEmpty && controller.isProductLoading) {
//           return const SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.only(top: 60),
//               child: Center(child: CircularProgressIndicator()),
//             ),
//           );
//         }
//
//         if (products.isEmpty) {
//           return SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 vertical: rs.isSmall ? 40 : 60,
//                 horizontal: rs.hPad,
//               ),
//               child: const Center(
//                 child: Text(
//                   'No products available',
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//               ),
//             ),
//           );
//         }
//
//         return SliverToBoxAdapter(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: rs.hPad),
//             child: Consumer<HomeProvider>(
//               builder: (context, _, __) {
//                 return GridView.builder(
//                   itemCount: products.length,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   padding: EdgeInsets.only(bottom: rs.gridSpacing),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: rs.gridCols,
//                     crossAxisSpacing: rs.gridSpacing,
//                     mainAxisSpacing: rs.gridSpacing,
//                     childAspectRatio: rs.gridAspectRatio,
//                   ),
//                   itemBuilder: (context, index) {
//                     final product = products[index];
//                     return RepaintBoundary(
//                       child: _ProductCard(product: product, rs: rs),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Card wrapper — Stack: PlaytimeProductCard + share overlay
// // ─────────────────────────────────────────────────────────────────────────────
// class _ProductCard extends StatelessWidget {
//   final MartItemModel product;
//   final _RS rs;
//
//   const _ProductCard({required this.product, required this.rs});
//
//   void _share() {
//     final price = product.price;
//     Share.share('Check out ${product.name} at ₹$price on JippyMart! 🛒');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final unit = (product.grams != null && product.grams! > 0)
//         ? '${product.grams}g'
//         : '';
//
//     return Stack(
//       children: [
//         PlaytimeProductCard(
//           rs: rs,
//           volume: unit,
//           productName: product.name,
//           currentPrice: '₹${product.price}',
//           imageUrl: product.photo,
//           product: product,
//           onTap: () {
//             HapticFeedback.selectionClick();
//             Get.to(() => MartProductDetailsScreen(product: product));
//           },
//         ),
//
//         // Share button — top right
//         Positioned(
//           top: rs.overlayPos,
//           right: rs.overlayPos,
//           child: GestureDetector(
//             onTap: _share,
//             child: Container(
//               width: rs.shareBtnSize,
//               height: rs.shareBtnSize,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.93),
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(color: Colors.grey.shade200, width: 0.5),
//               ),
//               child: Icon(
//                 Icons.share_outlined,
//                 size: rs.shareIconSize,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Qty stepper — ADD (large) or − n + synced with cart
// // ─────────────────────────────────────────────────────────────────────────────
// class _MartQtyStepper extends StatelessWidget {
//   final _RS rs;
//   final MartItemModel product;
//
//   const _MartQtyStepper({required this.rs, required this.product});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<MartProvider, CartProvider>(
//       builder: (context, mart, _, __) {
//         final vid = _martVendorId(product, mart);
//         final qty = _martQtyInCart(HomeProvider.cartItem, product, vid);
//         final r = rs.addStepperHeight / 2;
//
//         if (qty <= 0) {
//           return Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () =>
//                   _handleMartIncrement(context, product, showSnack: true),
//               borderRadius: BorderRadius.circular(r),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   minWidth: rs.addPillMinWidth,
//                   minHeight: rs.addStepperHeight,
//                 ),
//                 child: Ink(
//                   height: rs.addStepperHeight,
//                   padding: EdgeInsets.symmetric(horizontal: rs.addPillHPad),
//                   decoration: BoxDecoration(
//                     color: ColorConst.greenLight,
//                     borderRadius: BorderRadius.circular(r),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.add_rounded,
//                         color: Colors.white,
//                         size: rs.stepperIconSize,
//                       ),
//                       SizedBox(width: rs.isSmall ? 3 : 4),
//                       Text(
//                         'Add',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w700,
//                           fontSize: rs.addLabelFontSize,
//                           letterSpacing: 0.2,
//                           height: 1.0,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }
//
//         return Container(
//           height: rs.addStepperHeight,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(r),
//             border: Border.all(color: ColorConst.greenLight, width: 1),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () => _handleMartDecrement(context, product, qty),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(r),
//                     bottomLeft: Radius.circular(r),
//                   ),
//                   child: SizedBox(
//                     width: rs.stepperBtnWidth,
//                     height: rs.addStepperHeight,
//                     child: Icon(
//                       Icons.remove_rounded,
//                       color: ColorConst.greenLight,
//                       size: rs.stepperIconSize,
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: rs.qtyMidHPad),
//                 child: Text(
//                   '$qty',
//                   style: TextStyle(
//                     fontSize: rs.qtyCountFontSize,
//                     fontWeight: FontWeight.w700,
//                     color: const Color(0xFF1A1A1A),
//                     height: 1.0,
//                   ),
//                 ),
//               ),
//               Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () => _handleMartIncrement(context, product),
//                   borderRadius: BorderRadius.only(
//                     topRight: Radius.circular(r),
//                     bottomRight: Radius.circular(r),
//                   ),
//                   child: SizedBox(
//                     width: rs.stepperBtnWidth,
//                     height: rs.addStepperHeight,
//                     child: Icon(
//                       Icons.add_rounded,
//                       color: ColorConst.greenLight,
//                       size: rs.stepperIconSize,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // PlaytimeProductCard  — fully RS-driven, no magic numbers
// // ─────────────────────────────────────────────────────────────────────────────
// class PlaytimeProductCard extends StatelessWidget {
//   final _RS rs;
//   final String volume;
//   final String productName;
//   final String currentPrice;
//   final String? imageUrl;
//   final MartItemModel product;
//   final VoidCallback? onTap;
//
//   const PlaytimeProductCard({
//     super.key,
//     required this.rs,
//     required this.volume,
//     required this.productName,
//     required this.currentPrice,
//     required this.product,
//     this.imageUrl,
//     this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Image ──────────────────────────────────────────
//           GestureDetector(
//             onTap: onTap,
//             behavior: HitTestBehavior.opaque,
//             child: ClipRRect(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(10),
//               ),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: rs.imgHeight,
//                 child: imageUrl != null && imageUrl!.isNotEmpty
//                     ? CachedNetworkImage(
//                         imageUrl: imageUrl!,
//                         fit: BoxFit.cover,
//                         placeholder: (_, __) => const _ImgPlaceholder(),
//                         errorWidget: (_, __, ___) => const _ImgPlaceholder(),
//                       )
//                     : const _ImgPlaceholder(),
//               ),
//             ),
//           ),
//
//           // ── Body ───────────────────────────────────────────
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   GestureDetector(
//                     onTap: onTap,
//                     behavior: HitTestBehavior.opaque,
//                     child: Text(
//                       productName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: rs.nameFontSize,
//                         fontWeight: FontWeight.w600,
//                         color: const Color(0xFF1A1A1A),
//                         height: 1.25,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: rs.nameToPriceGap),
//
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             currentPrice,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize: rs.priceFontSize,
//                               fontWeight: FontWeight.w700,
//                               color: const Color(0xFFC0392B),
//                             ),
//                           ),
//                         ),
//                       ),
//                       _MartQtyStepper(rs: rs, product: product),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Image placeholder
// // ─────────────────────────────────────────────────────────────────────────────
// class _ImgPlaceholder extends StatelessWidget {
//   const _ImgPlaceholder();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFFF5F5F0),
//       child: const Center(
//         child: Icon(Icons.image_outlined, color: Color(0xFFCCCCC0), size: 30),
//       ),
//     );
//   }
// }

import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/widget/mart_header_card.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:jippymart_customer/themes/mart_theme.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../mart_search_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cart helpers
// ─────────────────────────────────────────────────────────────────────────────

String _martVendorId(MartItemModel product, MartProvider mart) =>
    'mart_${product.vendorID ?? mart.selectedVendorId}';

CartProductModel _martCartLine(
  MartItemModel product,
  MartProvider mart, {
  int quantity = 1,
}) => CartProductModel(
  id: product.id,
  name: product.name,
  photo: product.photo,
  price: product.price.toString(),
  discountPrice: product.price.toString(),
  vendorID: _martVendorId(product, mart),
  vendorName: 'Jippy Mart',
  categoryId: product.categoryID,
  quantity: quantity,
  extrasPrice: '0',
  extras: [],
  variantInfo: null,
  promoId: null,
);

int _martQtyInCart(
  List<CartProductModel> items,
  MartItemModel product,
  String martVendorId,
) {
  final pid = product.id;
  if (pid == null || pid.isEmpty) return 0;
  for (final item in items) {
    if (item.vendorID != martVendorId) continue;
    final iid = item.id;
    if (iid != null &&
        iid.isNotEmpty &&
        (iid == pid || iid.startsWith('$pid~'))) {
      return item.quantity ?? 0;
    }
  }
  return 0;
}

Future<void> _handleMartIncrement(
  BuildContext context,
  MartItemModel product, {
  bool showSnack = false,
}) async {
  final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
  if (!isLoggedIn) {
    if (!context.mounted) return;
    _showMartLoginDialog(context);
    return;
  }
  try {
    final mart = Provider.of<MartProvider>(context, listen: false);
    final cartCtrl = Provider.of<CartControllerProvider>(
      context,
      listen: false,
    );
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    await cartCtrl.addToCart(
      cartProductModel: _martCartLine(product, mart),
      isIncrement: true,
      quantity: 1,
    );
    await cartProv.initCart();

    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    if (showSnack) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not add to cart'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

Future<void> _handleMartDecrement(
  BuildContext context,
  MartItemModel product,
  int cartQuantity,
) async {
  if (cartQuantity <= 0) return;
  final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
  if (!isLoggedIn) {
    if (!context.mounted) return;
    _showMartLoginDialog(context);
    return;
  }
  try {
    final mart = Provider.of<MartProvider>(context, listen: false);
    final cartCtrl = Provider.of<CartControllerProvider>(
      context,
      listen: false,
    );
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    await cartCtrl.addToCart(
      cartProductModel: _martCartLine(product, mart, quantity: cartQuantity),
      isIncrement: false,
      quantity: cartQuantity > 1 ? cartQuantity - 1 : 0,
    );
    await cartProv.initCart();
    if (context.mounted) HapticFeedback.selectionClick();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not update cart'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

void _showMartLoginDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => CustomDialogBox(
      title: 'Login Required'.tr,
      descriptions:
          'Please login to add items to your cart and continue shopping.'.tr,
      positiveString: 'Login'.tr,
      negativeString: 'Cancel'.tr,
      positiveClick: () {
        Get.back();
        Get.to(() => PhoneNumberScreen());
      },
      negativeClick: () => Get.back(),
      img: Image.asset('assets/images/ic_launcher.png', height: 50, width: 50),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _RS — single source of truth for every dimension on screen
// ─────────────────────────────────────────────────────────────────────────────
class _RS {
  final double sw; // screen width
  final double sh; // screen height

  const _RS({required this.sw, required this.sh});

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  // ── grid ──────────────────────────────────────────────────────
  int get gridCols => sw >= 600 ? 3 : 2;

  double get gridSpacing => isSmall ? 8.0 : 10.0;

  /// Aspect ratio computed from actual content heights — no clipping, no overflow
  double get gridAspectRatio {
    final imgH = cardWidth * 0.70;
    // body: name(~18) + gap(4) + unit(~15) + gap(5) + price row(30) + top/bottom padding(16)
    const bodyH = 88.0;
    final total = imgH + bodyH;
    return cardWidth / total;
  }

  // ── layout ────────────────────────────────────────────────────
  double get hPad => isSmall ? 10.0 : (isLarge ? 16.0 : 12.0);

  // ── header ────────────────────────────────────────────────────
  double get headerRadius => isSmall ? 16.0 : 20.0;

  // ── search bar ────────────────────────────────────────────────
  double get searchBarH => isSmall ? 34.0 : (isLarge ? 42.0 : 38.0);

  double get searchIconSize => isSmall ? 14.0 : (isLarge ? 17.0 : 15.0);

  double get searchFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get searchRadius => isSmall ? 9.0 : (isLarge ? 12.0 : 10.0);

  // ── section label ─────────────────────────────────────────────
  double get sectionFontSize => isSmall ? 14.0 : (isLarge ? 16.0 : 15.0);

  // ── card image ────────────────────────────────────────────────
  double get cardWidth {
    final totalGap = hPad * 2 + gridSpacing * (gridCols - 1);
    return (sw - totalGap) / gridCols;
  }

  double get imgHeight => cardWidth * 0.70;

  // ── card text ─────────────────────────────────────────────────
  double get nameFontSize => isSmall ? 11.5 : (isLarge ? 13.0 : 12.0);

  double get unitFontSize => isSmall ? 10.0 : (isLarge ? 11.5 : 10.5);

  double get priceFontSize => isSmall ? 12.5 : (isLarge ? 14.0 : 13.0);

  double get nameToPriceGap => isSmall ? 3.0 : 4.0;

  // ── qty stepper ───────────────────────────────────────────────
  double get addStepperHeight => isSmall ? 28.0 : (isLarge ? 32.0 : 30.0);

  double get stepperBtnWidth => isSmall ? 28.0 : (isLarge ? 34.0 : 30.0);

  double get addPillMinWidth => isSmall ? 60.0 : (isLarge ? 76.0 : 66.0);

  double get addPillHPad => isSmall ? 8.0 : (isLarge ? 12.0 : 10.0);

  double get stepperIconSize => isSmall ? 15.0 : (isLarge ? 18.0 : 16.0);

  double get addLabelFontSize => isSmall ? 10.5 : (isLarge ? 12.0 : 11.0);

  double get qtyCountFontSize => isSmall ? 11.5 : (isLarge ? 13.0 : 12.0);

  double get qtyMidHPad => isSmall ? 4.0 : (isLarge ? 8.0 : 5.0);

  // ── share overlay ─────────────────────────────────────────────
  double get shareBtnSize => isSmall ? 24.0 : (isLarge ? 28.0 : 26.0);

  double get shareIconSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get overlayPos => isSmall ? 5.0 : 7.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// MartHomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class MartHomeScreen extends StatefulWidget {
  const MartHomeScreen({super.key});

  @override
  State<MartHomeScreen> createState() => _MartHomeScreenState();
}

class _MartHomeScreenState extends State<MartHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Guards against firing loadNextPage() multiple times in one burst
  bool _paginating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_paginating) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _paginating = true;
      context.read<MartProvider>().loadNextPage().whenComplete(() {
        _paginating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rs = _RS(sw: size.width, sh: size.height);

    return Theme(
      data: MartTheme.theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Consumer<MartProvider>(
          builder: (context, controller, _) {
            return RefreshIndicator(
              onRefresh: controller.refreshData,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Green header (tabs + address + search) ──────
                  SliverToBoxAdapter(
                    child: _MartHeader(rs: rs, screenWidth: size.width),
                  ),

                  // ── "All Products" row ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(rs.hPad, 14, rs.hPad, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: rs.sectionFontSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'See all',
                              style: TextStyle(
                                fontSize: rs.sectionFontSize - 1,
                                fontWeight: FontWeight.w600,
                                color: ColorConst.greenLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Empty / loading states ───────────────────────
                  if (controller.pagedProducts.isEmpty &&
                      controller.isProductLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.pagedProducts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No products available',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // ── Product grid (true SliverGrid — no shrinkWrap) ──
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: rs.hPad),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => RepaintBoundary(
                            child: _ProductCard(
                              product: controller.pagedProducts[i],
                              rs: rs,
                            ),
                          ),
                          childCount: controller.pagedProducts.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: rs.gridCols,
                          crossAxisSpacing: rs.gridSpacing,
                          mainAxisSpacing: rs.gridSpacing,
                          childAspectRatio: rs.gridAspectRatio,
                        ),
                      ),
                    ),
                  ],

                  // ── Pagination footer ───────────────────────────
                  SliverToBoxAdapter(
                    child: controller.isPaginating
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — green bg, MartHeaderCard (tabs + address), then search bar
// ─────────────────────────────────────────────────────────────────────────────
class _MartHeader extends StatelessWidget {
  final _RS rs;
  final double screenWidth;

  const _MartHeader({required this.rs, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConst.greenLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(rs.headerRadius),
          bottomRight: Radius.circular(rs.headerRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MartHeaderCard(screenWidth: screenWidth),
          Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 2, rs.hPad, 12),
            child: MartHomeSearchWidget(rs: rs),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────
class MartHomeSearchWidget extends StatelessWidget {
  final _RS rs;

  const MartHomeSearchWidget({super.key, required this.rs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MartSearchScreen()),
      ),
      child: Container(
        height: rs.searchBarH,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(rs.searchRadius),
        ),
        padding: EdgeInsets.symmetric(horizontal: rs.hPad * 0.85),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: rs.searchIconSize + 2,
              color: Colors.grey.shade400,
            ),
            SizedBox(width: rs.hPad * 0.5),
            Expanded(
              child: Text(
                'Search groceries, snacks…',
                style: TextStyle(
                  fontSize: rs.searchFontSize,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Mic icon for voice search (optional but good UX)
            Icon(
              Icons.mic_none_rounded,
              size: rs.searchIconSize + 1,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product card — Stack: PlaytimeProductCard + share overlay
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final MartItemModel product;
  final _RS rs;

  const _ProductCard({required this.product, required this.rs});

  void _share() {
    Share.share(
      'Check out ${product.name} at ₹${product.price} on JippyMart! 🛒',
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = (product.grams != null && product.grams! > 0)
        ? '${product.grams}g'
        : '';

    return Stack(
      children: [
        PlaytimeProductCard(
          rs: rs,
          volume: unit,
          productName: product.name,
          currentPrice: '₹${product.disPrice ?? product.price}',
          originalPrice:
              product.disPrice != null && product.price > product.disPrice!
              ? '₹${product.price}'
              : null,
          imageUrl: product.photo,
          product: product,
          onTap: () {
            HapticFeedback.selectionClick();
            Get.to(() => MartProductDetailsScreen(product: product));
          },
        ),

        // Share button — top-right overlay
        Positioned(
          top: rs.overlayPos,
          right: rs.overlayPos,
          child: GestureDetector(
            onTap: _share,
            child: Container(
              width: rs.shareBtnSize,
              height: rs.shareBtnSize,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Icon(
                Icons.share_outlined,
                size: rs.shareIconSize,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlaytimeProductCard — fully RS-driven, no magic numbers
// ─────────────────────────────────────────────────────────────────────────────
class PlaytimeProductCard extends StatelessWidget {
  final _RS rs;
  final String volume;
  final String productName;
  final String currentPrice;
  final String? originalPrice; // null means no strikethrough
  final String? imageUrl;
  final MartItemModel product;
  final VoidCallback? onTap;

  const PlaytimeProductCard({
    super.key,
    required this.rs,
    required this.volume,
    required this.productName,
    required this.currentPrice,
    required this.product,
    this.originalPrice,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product image ───────────────────────────────────
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: SizedBox(
                width: double.infinity,
                height: rs.imgHeight,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (_, __) => const _ImgPlaceholder(),
                        errorWidget: (_, __, ___) => const _ImgPlaceholder(),
                      )
                    : const _ImgPlaceholder(),
              ),
            ),
          ),

          // ── Card body ───────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rs.nameFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.25,
                      ),
                    ),
                  ),

                  // Unit / weight label
                  if (volume.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      volume,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rs.unitFontSize,
                        color: Colors.grey.shade500,
                        height: 1.2,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Price row + Add/stepper
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: rs.priceFontSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC0392B),
                                height: 1.2,
                              ),
                            ),
                            if (originalPrice != null)
                              Text(
                                originalPrice!,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: rs.unitFontSize,
                                  color: Colors.grey.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  height: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      _MartQtyStepper(rs: rs, product: product),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qty stepper — ADD pill (qty==0) or − n + stepper (qty>0)
// ─────────────────────────────────────────────────────────────────────────────
class _MartQtyStepper extends StatelessWidget {
  final _RS rs;
  final MartItemModel product;

  const _MartQtyStepper({required this.rs, required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MartProvider, CartProvider>(
      builder: (context, mart, _, __) {
        final vid = _martVendorId(product, mart);
        final qty = _martQtyInCart(HomeProvider.cartItem, product, vid);
        final r = rs.addStepperHeight / 2;

        if (qty <= 0) {
          // ── ADD pill ─────────────────────────────────────────
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(r),
            child: InkWell(
              onTap: () =>
                  _handleMartIncrement(context, product, showSnack: true),
              borderRadius: BorderRadius.circular(r),
              child: Ink(
                height: rs.addStepperHeight,
                padding: EdgeInsets.symmetric(horizontal: rs.addPillHPad),
                decoration: BoxDecoration(
                  color: ColorConst.greenLight,
                  borderRadius: BorderRadius.circular(r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: rs.stepperIconSize,
                    ),
                    SizedBox(width: rs.isSmall ? 3 : 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: rs.addLabelFontSize,
                        letterSpacing: 0.2,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── − qty + stepper ───────────────────────────────────
        return Container(
          height: rs.addStepperHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: ColorConst.greenLight, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleMartDecrement(context, product, qty),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(r),
                    bottomLeft: Radius.circular(r),
                  ),
                  child: SizedBox(
                    width: rs.stepperBtnWidth,
                    height: rs.addStepperHeight,
                    child: Icon(
                      Icons.remove_rounded,
                      color: ColorConst.greenLight,
                      size: rs.stepperIconSize,
                    ),
                  ),
                ),
              ),

              // Quantity label
              Padding(
                padding: EdgeInsets.symmetric(horizontal: rs.qtyMidHPad),
                child: Text(
                  '$qty',
                  style: TextStyle(
                    fontSize: rs.qtyCountFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    height: 1.0,
                  ),
                ),
              ),

              // Increment
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleMartIncrement(context, product),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(r),
                    bottomRight: Radius.circular(r),
                  ),
                  child: SizedBox(
                    width: rs.stepperBtnWidth,
                    height: rs.addStepperHeight,
                    child: Icon(
                      Icons.add_rounded,
                      color: ColorConst.greenLight,
                      size: rs.stepperIconSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F0),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFFCCCCC0), size: 32),
      ),
    );
  }
}
