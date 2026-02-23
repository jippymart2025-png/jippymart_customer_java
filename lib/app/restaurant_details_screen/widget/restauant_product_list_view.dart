// import 'dart:math';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/widget/restaurant_without_categories_wiget.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_product_details_view.dart';
// import 'package:jippymart_customer/constant/constant.dart' show Constant;
// import 'package:jippymart_customer/models/product_model.dart';
// import 'package:jippymart_customer/models/vendor_category_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:jippymart_customer/utils/network_image_widget.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
// import 'package:jippymart_customer/themes/custom_dialog_box.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import '../../../constant/show_toast_dialog.dart';
// import '../provider/PromotionIndicator.dart';
//
// class ProductListView extends StatelessWidget {
//   const ProductListView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 360;
//     final isLargeScreen = screenWidth > 600;
//
//     return Consumer<RestaurantDetailsProvider>(
//       builder: (context, controller, _) {
//         // NO LOADING INDICATOR - Show UI immediately
//         // Promotions will update as they load
//
//         return Container(
//           color: AppThemeData.grey50,
//           padding: EdgeInsets.symmetric(
//             horizontal: isSmallScreen ? 12 : (isLargeScreen ? 20 : 16),
//           ),
//           child: controller.productList.isEmpty
//               ? _buildNoProductsMessage(context)
//               : controller.vendorCategoryList.isEmpty
//               ? buildProductsWithoutCategories(context, controller)
//               : controller.searchEditingController.value.text.isNotEmpty ||
//                     controller.isVag ||
//                     controller.isNonVag ||
//                     controller.isOfferFilter
//               ? buildProductsWithoutCategories(context, controller)
//               : ListView.builder(
//                   controller: controller.scrollControllerProduct,
//                   shrinkWrap: true,
//                   padding: EdgeInsets.zero,
//                   itemCount: controller.vendorCategoryList.length,
//                   itemBuilder: (context, index) {
//                     VendorCategoryModel vendorCategoryModel =
//                         controller.vendorCategoryList[index];
//                     final categoryKey =
//                         controller.returnKeyCategories(index: index) ??
//                         'category_$index';
//                     return KeyedSubtree(
//                       key:
//                           controller.categoryKeys[categoryKey] ??
//                           ValueKey(categoryKey),
//                       child: _buildCategoryExpansionTile(
//                         context,
//                         vendorCategoryModel,
//                         index,
//                         controller,
//                       ),
//                     );
//                   },
//                 ),
//         );
//       },
//     );
//   }
//
//   Widget _buildCategoryExpansionTile(
//     BuildContext context,
//     VendorCategoryModel vendorCategoryModel,
//     int index,
//     RestaurantDetailsProvider controller,
//   ) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 360;
//     final fontSize = isSmallScreen ? 16.0 : (screenWidth > 600 ? 20.0 : 18.0);
//
//     return ExpansionTile(
//       childrenPadding: EdgeInsets.zero,
//       tilePadding: EdgeInsets.zero,
//       shape: const Border(),
//       initiallyExpanded: true,
//       onExpansionChanged: (expanded) {
//         if (expanded) {
//           print("Category ${vendorCategoryModel.title} expanded");
//         }
//       },
//       title: Text(
//         "${vendorCategoryModel.title.toString()} (${controller.getProductsByCategory(vendorCategoryModel.id.toString()).length})",
//         style: TextStyle(
//           fontSize: fontSize,
//           fontFamily: AppThemeData.semiBold,
//           fontWeight: FontWeight.w600,
//           color: AppThemeData.grey900,
//         ),
//       ),
//       children: [
//         Consumer<RestaurantDetailsProvider>(
//           builder: (context, controller, _) => _buildProductsForCategory(
//             vendorCategoryModel,
//             context,
//             controller,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildProductsForCategory(
//     VendorCategoryModel vendorCategoryModel,
//     BuildContext context,
//     RestaurantDetailsProvider controller,
//   ) {
//     final products = controller.getProductsByCategory(
//       vendorCategoryModel.id.toString(),
//     );
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 360;
//     final isLargeScreen = screenWidth > 600;
//
//     // Calculate responsive aspect ratio based on screen size
//     // Smaller screens need taller items, larger screens can be shorter
//     double aspectRatio = 0.60;
//     if (isSmallScreen) {
//       aspectRatio = 0.55; // Taller items on small screens
//     } else if (isLargeScreen) {
//       aspectRatio = 0.65; // Shorter items on large screens
//     } else if (screenHeight < 700) {
//       aspectRatio = 0.58; // Medium-small screens
//     }
//
//     return Consumer<HomeProvider>(
//       builder: (context, homeProvider, _) {
//         return GridView.builder(
//           itemCount: products.length,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: EdgeInsets.zero,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             crossAxisSpacing: isSmallScreen ? 6 : 8,
//             mainAxisSpacing: isSmallScreen ? 6 : 8,
//             childAspectRatio: aspectRatio,
//           ),
//           itemBuilder: (context, productIndex) {
//             ProductModel productModel = products[productIndex];
//             return _buildProductItem(
//               productModel,
//               context,
//               vendorCategoryModel,
//               productIndex,
//               controller,
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildProductItem(
//     ProductModel productModel,
//     BuildContext context,
//     VendorCategoryModel vendorCategoryModel,
//     int index,
//     RestaurantDetailsProvider controller,
//   ) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 360;
//     final isLargeScreen = screenWidth > 600;
//
//     bool isItemAvailable = productModel.isAvailable ?? true;
//
//     // Calculate base prices first
//     String basePrice = "0.0";
//     String baseDisPrice = "0.0";
//
//     if (productModel.itemAttribute != null &&
//         productModel.itemAttribute!.variants != null &&
//         productModel.itemAttribute!.variants!.isNotEmpty) {
//       // If no variant is selected yet, use the first variant as default
//       if (controller.selectedVariants.isEmpty) {
//         // Use the first variant's price as default
//         final firstVariant = productModel.itemAttribute!.variants!.first;
//         basePrice = Constant.productCommissionPrice(
//           controller.vendorModel,
//           firstVariant.variantPrice ?? '0',
//         );
//         baseDisPrice = "0";
//       } else {
//         // Use the selected variant's price
//         final selectedVariant = productModel.itemAttribute!.variants!
//             .firstWhere(
//               (element) =>
//                   element.variantSku == controller.selectedVariants.join('-'),
//               orElse: () => productModel.itemAttribute!.variants!.first,
//             );
//         basePrice = Constant.productCommissionPrice(
//           controller.vendorModel,
//           selectedVariant.variantPrice ?? '0',
//         );
//         baseDisPrice = "0";
//       }
//     } else {
//       // Regular product without variants
//       basePrice = Constant.productCommissionPrice(
//         controller.vendorModel,
//         productModel.price.toString(),
//       );
//       baseDisPrice = double.parse(productModel.disPrice.toString()) <= 0
//           ? "0"
//           : Constant.productCommissionPrice(
//               controller.vendorModel,
//               productModel.disPrice.toString(),
//             );
//     }
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Image section
//           Expanded(
//             flex: 3,
//             child: Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     topRight: Radius.circular(12),
//                   ),
//                   child: ColorFiltered(
//                     colorFilter: isItemAvailable
//                         ? const ColorFilter.mode(
//                             Colors.transparent,
//                             BlendMode.multiply,
//                           )
//                         : const ColorFilter.mode(
//                             Colors.grey,
//                             BlendMode.saturation,
//                           ),
//                     child: NetworkImageWidget(
//                       imageUrl: productModel.photo.toString(),
//                       fit: BoxFit.fill,
//                       width: double.infinity,
//                       height: double.infinity,
//                     ),
//                   ),
//                 ),
//                 // Use PromotionIndicator for image badge
//                 if (productModel.id != null && productModel.vendorID != null)
//                   PromotionIndicator(
//                     productId: productModel.id!.toString(),
//                     restaurantId: productModel.vendorID!,
//                     child: Container(),
//                   ),
//                 if (!isItemAvailable)
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.4),
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 Positioned(
//                   right: isSmallScreen ? 6 : 8,
//                   top: isSmallScreen ? 6 : 8,
//                   child: InkWell(
//                     onTap: () async {
//                       if (productModel.id == null ||
//                           productModel.id.toString().isEmpty) {
//                         ShowToastDialog.showToast("Invalid product data");
//                         return;
//                       }
//                       try {
//                         await controller.toggleProductFavorite(
//                           productModel.id!.toString(),
//                         );
//                       } catch (e) {
//                         ShowToastDialog.showToast("Failed to update favorites");
//                       }
//                     },
//                     child:
//                         controller.isProductFavorite(productModel.id.toString())
//                         ? SvgPicture.asset("assets/icons/ic_like_fill.svg")
//                         : SvgPicture.asset("assets/icons/ic_like.svg"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Details section
//           Expanded(
//             flex: 4,
//             child: Padding(
//               padding: EdgeInsets.all(
//                 isSmallScreen ? 5 : (isLargeScreen ? 8 : 6),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       productModel.nonveg == true
//                           ? SvgPicture.asset("assets/icons/ic_nonveg.svg")
//                           : SvgPicture.asset("assets/icons/ic_veg.svg"),
//                       SizedBox(width: isSmallScreen ? 3 : 4),
//                       Expanded(
//                         child: Text(
//                           productModel.nonveg == true
//                               ? "Non Veg.".tr
//                               : "Pure veg.".tr,
//                           style: TextStyle(
//                             fontSize: isSmallScreen
//                                 ? 8
//                                 : (isLargeScreen ? 10 : 9),
//                             color: productModel.nonveg == true
//                                 ? AppThemeData.danger300
//                                 : AppThemeData.success400,
//                             fontFamily: AppThemeData.semiBold,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: isSmallScreen ? 1 : 2),
//                   Text(
//                     productModel.name.toString(),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 11 : (isLargeScreen ? 13 : 12),
//                       color: AppThemeData.grey900,
//                       fontFamily: AppThemeData.semiBold,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 1 : 2),
//                   // Price display with promotion handling
//                   Consumer<RestaurantDetailsProvider>(
//                     builder: (context, controller, _) {
//                       final productId = productModel.id?.toString() ?? '';
//                       final restaurantId = productModel.vendorID ?? '';
//
//                       if (productId.isEmpty || restaurantId.isEmpty) {
//                         return Text(
//                           Constant.amountShow(amount: basePrice),
//                           style: TextStyle(
//                             fontSize: isSmallScreen
//                                 ? 11
//                                 : (isLargeScreen ? 13 : 12),
//                             color: AppThemeData.grey900,
//                             fontFamily: AppThemeData.semiBold,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         );
//                       }
//
//                       // Check if promotion exists
//                       final hasPromotion = controller.hasActivePromotion(
//                         productId,
//                         restaurantId,
//                       );
//
//                       // Get promotion data if exists
//                       final currentPromo = hasPromotion
//                           ? controller.getActivePromotionForProduct(
//                               productId: productId,
//                               restaurantId: restaurantId,
//                             )
//                           : null;
//
//                       // Handle promotional price
//                       if (currentPromo != null) {
//                         final promoPrice =
//                             (currentPromo['special_price'] as num).toString();
//                         final promoPriceNum = double.tryParse(promoPrice) ?? 0;
//                         final originalPriceNum =
//                             double.tryParse(basePrice) ?? 0;
//
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Flexible(
//                                   child: Text(
//                                     Constant.amountShow(amount: promoPrice),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: TextStyle(
//                                       fontSize: isSmallScreen
//                                           ? 11
//                                           : (isLargeScreen ? 13 : 12),
//                                       color: Colors.red,
//                                       fontFamily: AppThemeData.semiBold,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: isSmallScreen ? 3 : 4),
//                                 Flexible(
//                                   child: Text(
//                                     Constant.amountShow(amount: basePrice),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: TextStyle(
//                                       fontSize: isSmallScreen
//                                           ? 9
//                                           : (isLargeScreen ? 11 : 10),
//                                       decoration: TextDecoration.lineThrough,
//                                       decorationColor: AppThemeData.grey300,
//                                       color: AppThemeData.grey300,
//                                       fontFamily: AppThemeData.semiBold,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (originalPriceNum > 0 &&
//                                 promoPriceNum < originalPriceNum)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 2),
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 4,
//                                     vertical: 1,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         );
//                       }
//                       // Handle regular discount
//                       else if (double.parse(baseDisPrice) > 0) {
//                         return Row(
//                           children: [
//                             Flexible(
//                               child: Text(
//                                 Constant.amountShow(
//                                   amount: baseDisPrice.toString(),
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontSize: isSmallScreen
//                                       ? 11
//                                       : (isLargeScreen ? 13 : 12),
//                                   color: AppThemeData.grey900,
//                                   fontFamily: AppThemeData.semiBold,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: isSmallScreen ? 3 : 4),
//                             Flexible(
//                               child: Text(
//                                 Constant.amountShow(amount: basePrice),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontSize: isSmallScreen
//                                       ? 9
//                                       : (isLargeScreen ? 11 : 10),
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationColor: AppThemeData.grey300,
//                                   color: AppThemeData.grey300,
//                                   fontFamily: AppThemeData.semiBold,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }
//                       // Normal price (no discount)
//                       else {
//                         return Text(
//                           Constant.amountShow(amount: basePrice),
//                           style: TextStyle(
//                             fontSize: isSmallScreen
//                                 ? 11
//                                 : (isLargeScreen ? 13 : 12),
//                             color: AppThemeData.grey900,
//                             fontFamily: AppThemeData.semiBold,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                   SizedBox(height: isSmallScreen ? 3 : 4),
//                   // Rating display
//                   _buildRatingWidget(
//                     productModel,
//                     isSmallScreen,
//                     isLargeScreen,
//                   ),
//                   if (!isItemAvailable)
//                     Padding(
//                       padding: EdgeInsets.only(top: isSmallScreen ? 1 : 2),
//                       child: Text(
//                         "Not Available",
//                         style: TextStyle(
//                           fontSize: isSmallScreen
//                               ? 9
//                               : (isLargeScreen ? 11 : 10),
//                           color: Colors.red,
//                           fontFamily: AppThemeData.medium,
//                         ),
//                       ),
//                     ),
//                   const Spacer(),
//                   // Add to cart button
//                   if (controller.canAcceptOrders() && isItemAvailable)
//                     _buildAddToCartButton(
//                       controller,
//                       productModel,
//                       basePrice,
//                       baseDisPrice,
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRatingWidget(
//     ProductModel productModel,
//     bool isSmallScreen,
//     bool isLargeScreen,
//   ) {
//     // Generate consistent random rating based on product ID
//     final productId = productModel.id?.toString() ?? '0';
//     final random = Random(productId.hashCode);
//     final rating =
//         3.0 + (random.nextDouble() * 2.0); // Rating between 3.0 and 5.0
//     final ratingText = rating.toStringAsFixed(1);
//     final fullStars = rating.floor();
//     final hasHalfStar = (rating - fullStars) >= 0.5;
//
//     final iconSize = isSmallScreen ? 13.0 : (isLargeScreen ? 17.0 : 15.0);
//     final fontSize = isSmallScreen ? 11.0 : (isLargeScreen ? 13.0 : 12.0);
//
//     return Row(
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: List.generate(1, (index) {
//             if (index < fullStars) {
//               return Icon(Icons.star, size: iconSize, color: Colors.amber);
//             } else if (index == fullStars && hasHalfStar) {
//               return Icon(Icons.star_half, size: iconSize, color: Colors.amber);
//             } else {
//               return Icon(
//                 Icons.star_border,
//                 size: iconSize,
//                 color: AppThemeData.grey300,
//               );
//             }
//           }),
//         ),
//         SizedBox(width: isSmallScreen ? 3 : 4),
//         Text(
//           ratingText,
//           style: TextStyle(
//             fontSize: fontSize,
//             color: AppThemeData.grey600,
//             fontFamily: AppThemeData.medium,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAddToCartButton(
//     RestaurantDetailsProvider controller,
//     ProductModel productModel,
//     String basePrice,
//     String baseDisPrice,
//   ) {
//     final screenWidth = MediaQuery.of(Get.context!).size.width;
//     final isSmallScreen = screenWidth < 360;
//     final isLargeScreen = screenWidth > 600;
//     final buttonHeight = isSmallScreen ? 28.0 : (isLargeScreen ? 36.0 : 32.0);
//     final fontSize = isSmallScreen ? 12.0 : (isLargeScreen ? 14.0 : 13.0);
//     final iconSize = isSmallScreen ? 14.0 : (isLargeScreen ? 18.0 : 16.0);
//
//     final productId = productModel.id?.toString() ?? '';
//     final hasVariantsOrAddons =
//         controller.selectedVariants.isNotEmpty ||
//         (productModel.addOnsTitle != null &&
//             productModel.addOnsTitle!.isNotEmpty);
//
//     // Check for promotion
//     final promo = controller.getActivePromotionForProduct(
//       productId: productId,
//       restaurantId: productModel.vendorID ?? '',
//     );
//     final hasPromo = promo != null;
//
//     // Fix: Handle variant IDs
//     final isInCart = HomeProvider.cartItem.any((cartItem) {
//       if (cartItem.id == null || cartItem.id!.isEmpty) return false;
//       return cartItem.id == productId || cartItem.id!.startsWith('$productId~');
//     });
//
//     // Determine which prices to pass to addToCart
//     String priceToPass = basePrice;
//     String disPriceToPass = baseDisPrice;
//
//     if (hasPromo) {
//       priceToPass = (promo['special_price'] as num).toString();
//       disPriceToPass = basePrice;
//     } else if (double.parse(baseDisPrice) > 0) {
//       priceToPass = baseDisPrice;
//       disPriceToPass = basePrice;
//     }
//
//     if (hasVariantsOrAddons) {
//       return Container(
//         width: double.infinity,
//         height: buttonHeight,
//         decoration: BoxDecoration(
//           color: AppThemeData.primary300,
//           borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
//           boxShadow: [
//             BoxShadow(
//               color: AppThemeData.primary300.withOpacity(0.3),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () async {
//               final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//               if (!isLoggedIn) {
//                 _showLoginRequiredDialog(Get.context!);
//                 return;
//               }
//               controller.selectedVariants.clear();
//               controller.selectedIndexVariants.clear();
//               controller.selectedIndexArray.clear();
//               controller.selectedAddOns.clear();
//               controller.quantity = 1;
//               controller.calculatePrice(productModel);
//               productDetailsBottomSheet(Get.context!, productModel);
//             },
//             borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
//             child: Center(
//               child: Text(
//                 "Add".tr,
//                 style: TextStyle(
//                   fontSize: fontSize,
//                   fontFamily: AppThemeData.semiBold,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     } else if (isInCart) {
//       return Container(
//         width: double.infinity,
//         height: buttonHeight,
//         decoration: BoxDecoration(
//           color: AppThemeData.primary300,
//           borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
//           boxShadow: [
//             BoxShadow(
//               color: AppThemeData.primary300.withOpacity(0.3),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () {
//                   final currentPromo = controller.getActivePromotionForProduct(
//                     productId: productId,
//                     restaurantId: productModel.vendorID ?? '',
//                   );
//                   String finalPrice = priceToPass;
//                   String finalDiscountPrice = disPriceToPass;
//
//                   if (currentPromo != null) {
//                     finalPrice = (currentPromo['special_price'] as num)
//                         .toString();
//                     finalDiscountPrice = basePrice;
//                   }
//                   controller.addToCart(
//                     productModel: productModel,
//                     price: finalPrice,
//                     discountPrice: finalDiscountPrice,
//                     isIncrement: false,
//                     quantity: _findCartItemQuantity(productId) - 1,
//                   );
//                 },
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(isSmallScreen ? 6 : 8),
//                   bottomLeft: Radius.circular(isSmallScreen ? 6 : 8),
//                 ),
//                 child: Container(
//                   padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
//                   child: Icon(
//                     Icons.remove,
//                     size: iconSize,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
//               child: Text(
//                 _findCartItemQuantity(productId).toString(),
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 13 : (isLargeScreen ? 15 : 14),
//                   fontFamily: AppThemeData.semiBold,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () async {
//                   final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//                   if (!isLoggedIn) {
//                     _showLoginRequiredDialog(Get.context!);
//                     return;
//                   }
//                   final currentQty = _findCartItemQuantity(productId);
//                   if ((currentQty) <= (productModel.quantity ?? 0) ||
//                       (productModel.quantity ?? 0) == -1) {
//                     final currentPromo = controller
//                         .getActivePromotionForProduct(
//                           productId: productId,
//                           restaurantId: productModel.vendorID ?? '',
//                         );
//
//                     if (currentPromo != null) {
//                       final isAllowed = controller
//                           .isPromotionalItemQuantityAllowed(
//                             productId,
//                             productModel.vendorID ?? '',
//                             currentQty + 1,
//                           );
//
//                       if (!isAllowed) {
//                         final limit = controller.getPromotionalItemLimit(
//                           productId,
//                           productModel.vendorID ?? '',
//                         );
//                         ShowToastDialog.showToast(
//                           "Maximum $limit items allowed for this promotional offer"
//                               .tr,
//                         );
//                         return;
//                       }
//                     }
//
//                     String finalPrice = priceToPass;
//                     String finalDiscountPrice = disPriceToPass;
//                     if (currentPromo != null) {
//                       finalPrice = (currentPromo['special_price'] as num)
//                           .toString();
//                       finalDiscountPrice = basePrice;
//                     }
//                     controller.addToCart(
//                       productModel: productModel,
//                       price: finalPrice,
//                       discountPrice: finalDiscountPrice,
//                       isIncrement: true,
//                       quantity: currentQty + 1,
//                     );
//                   } else {
//                     ShowToastDialog.showToast("Out of stock".tr);
//                   }
//                 },
//                 borderRadius: BorderRadius.only(
//                   topRight: Radius.circular(isSmallScreen ? 6 : 8),
//                   bottomRight: Radius.circular(isSmallScreen ? 6 : 8),
//                 ),
//                 child: Container(
//                   padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
//                   child: Icon(Icons.add, size: iconSize, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Container(
//         width: double.infinity,
//         height: buttonHeight,
//         decoration: BoxDecoration(
//           color: AppThemeData.primary300,
//           borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
//           boxShadow: [
//             BoxShadow(
//               color: AppThemeData.primary300.withOpacity(0.3),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () async {
//               final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//               if (!isLoggedIn) {
//                 _showLoginRequiredDialog(Get.context!);
//                 return;
//               }
//               controller.addProductAndRemoveProductFunction(
//                 productModel: productModel,
//                 price: priceToPass,
//                 disPrice: disPriceToPass,
//               );
//             },
//             borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
//             child: Center(
//               child: Text(
//                 "Add".tr,
//                 style: TextStyle(
//                   fontSize: fontSize,
//                   fontFamily: AppThemeData.semiBold,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//   }
//
//   void _showLoginRequiredDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return CustomDialogBox(
//           title: "Login Required".tr,
//           descriptions:
//               "Please login to add items to your cart and continue shopping."
//                   .tr,
//           positiveString: "Login".tr,
//           negativeString: "Cancel".tr,
//           positiveClick: () {
//             Get.back();
//             Get.to(() => PhoneNumberScreen());
//           },
//           negativeClick: () {
//             Get.back();
//           },
//           img: Image.asset(
//             'assets/images/ic_launcher.png',
//             height: 50,
//             width: 50,
//           ),
//         );
//       },
//     );
//   }
//
//   int _findCartItemQuantity(String productId) {
//     if (productId.isEmpty) return 0;
//
//     final matchingItems = HomeProvider.cartItem.where((cartItem) {
//       if (cartItem.id == null || cartItem.id!.isEmpty) return false;
//       return cartItem.id == productId || cartItem.id!.startsWith('$productId~');
//     }).toList();
//
//     if (matchingItems.isEmpty) return 0;
//
//     return matchingItems.fold<int>(
//       0,
//       (sum, item) => sum + (item.quantity ?? 0),
//     );
//   }
// }
//
// // Keep existing helper methods
// productDetailsBottomSheet(BuildContext context, ProductModel productModel) {
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     isDismissible: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//     ),
//     clipBehavior: Clip.antiAliasWithSaveLayer,
//     builder: (context) => FractionallySizedBox(
//       heightFactor: 0.85,
//       child: StatefulBuilder(
//         builder: (context1, setState) {
//           return ProductDetailsView(productModel: productModel);
//         },
//       ),
//     ),
//   );
// }
//
// infoDialog(RestaurantDetailsProvider controller, ProductModel productModel) {
//   return Dialog(
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//     insetPadding: const EdgeInsets.all(10),
//     clipBehavior: Clip.antiAliasWithSaveLayer,
//     backgroundColor: AppThemeData.surface,
//     child: Padding(
//       padding: const EdgeInsets.all(30),
//       child: SizedBox(
//         width: 500,
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//                 child: Text(
//                   "Food Information's".tr,
//                   textAlign: TextAlign.start,
//                   style: TextStyle(
//                     fontFamily: AppThemeData.semiBold,
//                     color: AppThemeData.grey900,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 productModel.description.toString(),
//                 textAlign: TextAlign.start,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.regular,
//                   fontWeight: FontWeight.w400,
//                   color: AppThemeData.grey900,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               RoundedButtonFill(
//                 title: "Back".tr,
//                 color: AppThemeData.primary300,
//                 textColor: AppThemeData.grey50,
//                 onPress: () async {
//                   Get.back();
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }
//
// Widget _buildNoProductsMessage(BuildContext context) {
//   final screenWidth = MediaQuery.of(context).size.width;
//   final isSmallScreen = screenWidth < 360;
//   final isLargeScreen = screenWidth > 600;
//
//   return Container(
//     padding: EdgeInsets.symmetric(
//       vertical: isSmallScreen ? 40 : (isLargeScreen ? 80 : 60),
//       horizontal: isSmallScreen ? 16 : (isLargeScreen ? 24 : 20),
//     ),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(
//           Icons.restaurant_menu_outlined,
//           size: isSmallScreen ? 60 : (isLargeScreen ? 100 : 80),
//           color: AppThemeData.grey600,
//         ),
//         SizedBox(height: isSmallScreen ? 16 : (isLargeScreen ? 24 : 20)),
//         Text(
//           "No products available here".tr,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 16 : (isLargeScreen ? 20 : 18),
//             fontWeight: FontWeight.w600,
//             color: AppThemeData.grey700,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         SizedBox(height: isSmallScreen ? 8 : (isLargeScreen ? 12 : 10)),
//         Text(
//           "This restaurant doesn't have any items in their menu right now.".tr,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 12 : (isLargeScreen ? 16 : 14),
//             color: AppThemeData.grey600,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     ),
//   );
// }

import 'dart:math';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restaurant_without_categories_wiget.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_product_details_view.dart';
import 'package:jippymart_customer/constant/constant.dart' show Constant;
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../constant/show_toast_dialog.dart';
import '../provider/PromotionIndicator.dart';

// ── Responsive sizing helper ───────────────────────────────────────
// Computed ONCE in build(), passed down — zero extra MediaQuery calls
class _RS {
  final double sw;
  final double sh;

  const _RS({required this.sw, required this.sh});

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  // Grid
  int get gridCols => isLarge ? 3 : 2;

  double get gridSpacing => isSmall ? 6.0 : 8.0;

  double get gridAspectRatio {
    if (isSmall) return 0.55;
    if (isLarge) return 0.65;
    if (sh < 700) return 0.58;
    return 0.60;
  }

  // Padding
  double get hPad => isSmall ? 12.0 : (isLarge ? 20.0 : 16.0);

  double get itemPad => isSmall ? 5.0 : (isLarge ? 8.0 : 6.0);

  // Font sizes
  double get categoryFontSize => isSmall ? 16.0 : (isLarge ? 20.0 : 18.0);

  double get labelFontSize => isSmall ? 8.0 : (isLarge ? 10.0 : 9.0);

  double get nameFontSize => isSmall ? 11.0 : (isLarge ? 13.0 : 12.0);

  double get priceFontSize => isSmall ? 11.0 : (isLarge ? 13.0 : 12.0);

  double get strikethroughFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get ratingFontSize => isSmall ? 11.0 : (isLarge ? 13.0 : 12.0);

  double get unavailableFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get btnFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get btnIconSize => isSmall ? 14.0 : (isLarge ? 18.0 : 16.0);

  double get qtyFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get ratingIconSize => isSmall ? 13.0 : (isLarge ? 17.0 : 15.0);

  // Spacing
  double get labelGap => isSmall ? 3.0 : 4.0;

  double get nameGap => isSmall ? 1.0 : 2.0;

  double get ratingGap => isSmall ? 3.0 : 4.0;

  double get unavailableTopPad => isSmall ? 1.0 : 2.0;

  // Button
  double get btnHeight => isSmall ? 28.0 : (isLarge ? 36.0 : 32.0);

  double get btnRadius => isSmall ? 6.0 : 8.0;

  double get btnInnerPad => isSmall ? 6.0 : 8.0;

  double get qtyHPad => isSmall ? 8.0 : 12.0;

  // Favorite icon position
  double get favIconPos => isSmall ? 6.0 : 8.0;

  // No-products message
  double get emptyVPad => isSmall ? 40.0 : (isLarge ? 80.0 : 60.0);

  double get emptyHPad => isSmall ? 16.0 : (isLarge ? 24.0 : 20.0);

  double get emptyIconSize => isSmall ? 60.0 : (isLarge ? 100.0 : 80.0);

  double get emptyTitleSize => isSmall ? 16.0 : (isLarge ? 20.0 : 18.0);

  double get emptySubSize => isSmall ? 12.0 : (isLarge ? 16.0 : 14.0);

  double get emptyTitleGap => isSmall ? 16.0 : (isLarge ? 24.0 : 20.0);

  double get emptySubGap => isSmall ? 8.0 : (isLarge ? 12.0 : 10.0);
}

// ─────────────────────────────────────────────────────────────────────────────

class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Single MediaQuery call — compute rs once, pass everywhere ──
    final size = MediaQuery.sizeOf(context);
    final rs = _RS(sw: size.width, sh: size.height);

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        return Container(
          color: AppThemeData.grey50,
          padding: EdgeInsets.symmetric(horizontal: rs.hPad),
          child: controller.productList.isEmpty
              ? _buildNoProductsMessage(context, rs)
              : controller.vendorCategoryList.isEmpty
              ? buildProductsWithoutCategories(context, controller)
              : controller.searchEditingController.value.text.isNotEmpty ||
                    controller.isVag ||
                    controller.isNonVag ||
                    controller.isOfferFilter
              ? buildProductsWithoutCategories(context, controller)
              : ListView.builder(
                  controller: controller.scrollControllerProduct,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: controller.vendorCategoryList.length,
                  itemBuilder: (context, index) {
                    final vendorCategoryModel =
                        controller.vendorCategoryList[index];
                    final categoryKey =
                        controller.returnKeyCategories(index: index) ??
                        'category_$index';
                    return KeyedSubtree(
                      key:
                          controller.categoryKeys[categoryKey] ??
                          ValueKey(categoryKey),
                      // Pass rs — no MediaQuery inside itemBuilder
                      child: _buildCategoryExpansionTile(
                        context,
                        vendorCategoryModel,
                        index,
                        controller,
                        rs,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // ── Category tile ─────────────────────────────────────────────────
  Widget _buildCategoryExpansionTile(
    BuildContext context,
    VendorCategoryModel vendorCategoryModel,
    int index,
    RestaurantDetailsProvider controller,
    _RS rs,
  ) {
    return ExpansionTile(
      childrenPadding: EdgeInsets.zero,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      initiallyExpanded: true,
      title: Text(
        '${vendorCategoryModel.title}'
        ' (${controller.getProductsByCategory(vendorCategoryModel.id.toString()).length})',
        style: TextStyle(
          fontSize: rs.categoryFontSize,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w600,
          color: AppThemeData.grey900,
        ),
      ),
      children: [
        // Inner Consumer is fine — only rebuilds when provider changes
        Consumer<RestaurantDetailsProvider>(
          builder: (context, ctrl, _) =>
              _buildProductsForCategory(vendorCategoryModel, context, ctrl, rs),
        ),
      ],
    );
  }

  // ── Products grid for a category ─────────────────────────────────
  Widget _buildProductsForCategory(
    VendorCategoryModel vendorCategoryModel,
    BuildContext context,
    RestaurantDetailsProvider controller,
    _RS rs,
  ) {
    final products = controller.getProductsByCategory(
      vendorCategoryModel.id.toString(),
    );

    return Consumer<HomeProvider>(
      builder: (context, _, __) {
        return GridView.builder(
          itemCount: products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rs.gridCols,
            crossAxisSpacing: rs.gridSpacing,
            mainAxisSpacing: rs.gridSpacing,
            childAspectRatio: rs.gridAspectRatio,
          ),
          itemBuilder: (context, productIndex) {
            final productModel = products[productIndex];
            // RepaintBoundary isolates each card repaint
            return RepaintBoundary(
              child: _buildProductItem(
                productModel,
                context,
                vendorCategoryModel,
                productIndex,
                controller,
                rs,
              ),
            );
          },
        );
      },
    );
  }

  // ── Product card ─────────────────────────────────────────────────
  Widget _buildProductItem(
    ProductModel productModel,
    BuildContext context,
    VendorCategoryModel vendorCategoryModel,
    int index,
    RestaurantDetailsProvider controller,
    _RS rs,
  ) {
    final isItemAvailable = productModel.isAvailable ?? true;

    // ── Price computation (done once per card, not per rebuild) ──
    String basePrice = '0.0';
    String baseDisPrice = '0.0';

    if (productModel.itemAttribute != null &&
        productModel.itemAttribute!.variants != null &&
        productModel.itemAttribute!.variants!.isNotEmpty) {
      final variant = controller.selectedVariants.isEmpty
          ? productModel.itemAttribute!.variants!.first
          : productModel.itemAttribute!.variants!.firstWhere(
              (e) => e.variantSku == controller.selectedVariants.join('-'),
              orElse: () => productModel.itemAttribute!.variants!.first,
            );
      basePrice = Constant.productCommissionPrice(
        controller.vendorModel,
        variant.variantPrice ?? '0',
      );
      baseDisPrice = '0';
    } else {
      basePrice = Constant.productCommissionPrice(
        controller.vendorModel,
        productModel.price.toString(),
      );
      baseDisPrice = double.parse(productModel.disPrice.toString()) <= 0
          ? '0'
          : Constant.productCommissionPrice(
              controller.vendorModel,
              productModel.disPrice.toString(),
            );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: ColorFiltered(
                    colorFilter: isItemAvailable
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          )
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                    child: NetworkImageWidget(
                      imageUrl: productModel.photo.toString(),
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),

                // Promotion badge
                if (productModel.id != null && productModel.vendorID != null)
                  PromotionIndicator(
                    productId: productModel.id!.toString(),
                    restaurantId: productModel.vendorID!,
                    child: Container(),
                  ),

                // Unavailable overlay
                if (!isItemAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x66000000),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),

                // Favorite button
                Positioned(
                  right: rs.favIconPos,
                  top: rs.favIconPos,
                  child: InkWell(
                    onTap: () async {
                      if (productModel.id == null ||
                          productModel.id.toString().isEmpty) {
                        ShowToastDialog.showToast('Invalid product data');
                        return;
                      }
                      try {
                        await controller.toggleProductFavorite(
                          productModel.id!.toString(),
                        );
                      } catch (_) {
                        ShowToastDialog.showToast('Failed to update favorites');
                      }
                    },
                    child:
                        controller.isProductFavorite(productModel.id.toString())
                        ? SvgPicture.asset('assets/icons/ic_like_fill.svg')
                        : SvgPicture.asset('assets/icons/ic_like.svg'),
                  ),
                ),
              ],
            ),
          ),

          // ── Details ────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              // Reduce outer padding — was rs.itemPad (5–8px), now tighter
              padding: EdgeInsets.fromLTRB(
                rs.itemPad,
                rs.itemPad - 1,
                rs.itemPad,
                rs.itemPad - 1,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // replaces Spacer()
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top group: veg label + name + price + rating ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Veg / Non-veg label
                      Row(
                        children: [
                          SizedBox(
                            // constrain SVG size so it doesn't eat row space
                            width: rs.labelFontSize + 2,
                            height: rs.labelFontSize + 2,
                            child: productModel.nonveg == true
                                ? SvgPicture.asset(
                                    'assets/icons/ic_nonveg.svg',
                                    fit: BoxFit.contain,
                                  )
                                : SvgPicture.asset(
                                    'assets/icons/ic_veg.svg',
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          SizedBox(width: rs.labelGap - 1),
                          Expanded(
                            child: Text(
                              productModel.nonveg == true
                                  ? 'Non Veg.'.tr
                                  : 'Pure veg.'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: rs.labelFontSize,
                                color: productModel.nonveg == true
                                    ? AppThemeData.danger300
                                    : AppThemeData.success400,
                                fontFamily: AppThemeData.semiBold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // No gap between label and name — they sit close
                      const SizedBox(height: 1),

                      // Product name — 1 line max to save space
                      Text(
                        productModel.name.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: rs.nameFontSize,
                          color: AppThemeData.grey900,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                          height: 1.1, // tighter line height
                        ),
                      ),

                      const SizedBox(height: 1),

                      // Price
                      Consumer<RestaurantDetailsProvider>(
                        builder: (context, ctrl, _) {
                          final productId = productModel.id?.toString() ?? '';
                          final restaurantId = productModel.vendorID ?? '';

                          if (productId.isEmpty || restaurantId.isEmpty) {
                            return _PriceText(
                              amount: basePrice,
                              fontSize: rs.priceFontSize,
                            );
                          }

                          final currentPromo =
                              ctrl.hasActivePromotion(productId, restaurantId)
                              ? ctrl.getActivePromotionForProduct(
                                  productId: productId,
                                  restaurantId: restaurantId,
                                )
                              : null;

                          if (currentPromo != null) {
                            final promoPrice =
                                (currentPromo['special_price'] as num)
                                    .toString();
                            return _PromoPriceRow(
                              promoPrice: promoPrice,
                              originalPrice: basePrice,
                              rs: rs,
                            );
                          }

                          if (double.parse(baseDisPrice) > 0) {
                            return _DiscountPriceRow(
                              discountPrice: baseDisPrice,
                              originalPrice: basePrice,
                              rs: rs,
                            );
                          }

                          return _PriceText(
                            amount: basePrice,
                            fontSize: rs.priceFontSize,
                          );
                        },
                      ),

                      // Rating — no gap above, sits right under price
                      _RatingWidget(productModel: productModel, rs: rs),

                      // Not available — only shown when needed
                      if (!isItemAvailable)
                        Text(
                          'Not Available',
                          style: TextStyle(
                            fontSize: rs.unavailableFontSize,
                            color: Colors.red,
                            fontFamily: AppThemeData.medium,
                            height: 1.1,
                          ),
                        ),
                    ],
                  ),

                  // ── Bottom: Add to cart button — pinned to bottom ──
                  if (controller.canAcceptOrders() && isItemAvailable)
                    _AddToCartButton(
                      controller: controller,
                      productModel: productModel,
                      basePrice: basePrice,
                      baseDisPrice: baseDisPrice,
                      rs: rs,
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

// ── Small price widgets — extracted to avoid rebuilding parent ─────

class _PriceText extends StatelessWidget {
  final String amount;
  final double fontSize;

  const _PriceText({required this.amount, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      Constant.amountShow(amount: amount),
      style: TextStyle(
        fontSize: fontSize,
        color: AppThemeData.grey900,
        fontFamily: AppThemeData.semiBold,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PromoPriceRow extends StatelessWidget {
  final String promoPrice;
  final String originalPrice;
  final _RS rs;

  const _PromoPriceRow({
    required this.promoPrice,
    required this.originalPrice,
    required this.rs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            Constant.amountShow(amount: promoPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.priceFontSize,
              color: Colors.red,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: rs.labelGap),
        Flexible(
          child: Text(
            Constant.amountShow(amount: originalPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.strikethroughFontSize,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey300,
              color: AppThemeData.grey300,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscountPriceRow extends StatelessWidget {
  final String discountPrice;
  final String originalPrice;
  final _RS rs;

  const _DiscountPriceRow({
    required this.discountPrice,
    required this.originalPrice,
    required this.rs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            Constant.amountShow(amount: discountPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.priceFontSize,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: rs.labelGap),
        Flexible(
          child: Text(
            Constant.amountShow(amount: originalPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.strikethroughFontSize,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey300,
              color: AppThemeData.grey300,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rating widget — extracted so Random() runs once per widget ─────

class _RatingWidget extends StatelessWidget {
  final ProductModel productModel;
  final _RS rs;

  const _RatingWidget({required this.productModel, required this.rs});

  @override
  Widget build(BuildContext context) {
    // Random seeded by product ID — stable across rebuilds for same product
    final productId = productModel.id?.toString() ?? '0';
    final random = Random(productId.hashCode);
    final rating = 3.0 + (random.nextDouble() * 2.0);
    final ratingText = rating.toStringAsFixed(1);
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        // Only 1 star shown (as per original)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(1, (index) {
            if (index < fullStars) {
              return Icon(
                Icons.star,
                size: rs.ratingIconSize,
                color: Colors.amber,
              );
            } else if (index == fullStars && hasHalfStar) {
              return Icon(
                Icons.star_half,
                size: rs.ratingIconSize,
                color: Colors.amber,
              );
            }
            return Icon(
              Icons.star_border,
              size: rs.ratingIconSize,
              color: AppThemeData.grey300,
            );
          }),
        ),
        SizedBox(width: rs.labelGap),
        Text(
          ratingText,
          style: TextStyle(
            fontSize: rs.ratingFontSize,
            color: AppThemeData.grey600,
            fontFamily: AppThemeData.medium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Add to cart button — extracted widget, uses passed context ─────
// Eliminates Get.context! usage entirely

class _AddToCartButton extends StatelessWidget {
  final RestaurantDetailsProvider controller;
  final ProductModel productModel;
  final String basePrice;
  final String baseDisPrice;
  final _RS rs;

  const _AddToCartButton({
    required this.controller,
    required this.productModel,
    required this.basePrice,
    required this.baseDisPrice,
    required this.rs,
  });

  String get _productId => productModel.id?.toString() ?? '';

  bool get _hasVariantsOrAddons =>
      controller.selectedVariants.isNotEmpty ||
      (productModel.addOnsTitle != null &&
          productModel.addOnsTitle!.isNotEmpty);

  bool get _isInCart => HomeProvider.cartItem.any((item) {
    if (item.id == null || item.id!.isEmpty) return false;
    return item.id == _productId || item.id!.startsWith('$_productId~');
  });

  int get _cartQty {
    if (_productId.isEmpty) return 0;
    return HomeProvider.cartItem
        .where(
          (item) =>
              item.id != null &&
              (item.id == _productId || item.id!.startsWith('$_productId~')),
        )
        .fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  Map<String, dynamic>? get _promo => controller.getActivePromotionForProduct(
    productId: _productId,
    restaurantId: productModel.vendorID ?? '',
  );

  String get _priceToPass {
    final p = _promo;
    if (p != null) return (p['special_price'] as num).toString();
    if (double.parse(baseDisPrice) > 0) return baseDisPrice;
    return basePrice;
  }

  String get _disPriceToPass {
    final p = _promo;
    if (p != null) return basePrice;
    if (double.parse(baseDisPrice) > 0) return basePrice;
    return baseDisPrice;
  }

  // Shared button container decoration
  BoxDecoration get _btnDecoration => BoxDecoration(
    color: AppThemeData.primary300,
    borderRadius: BorderRadius.circular(rs.btnRadius),
    boxShadow: [
      BoxShadow(
        color: AppThemeData.primary300.withOpacity(0.3),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_hasVariantsOrAddons) {
      return _buildVariantButton(context);
    } else if (_isInCart) {
      return _buildInCartButton(context);
    } else {
      return _buildAddButton(context);
    }
  }

  // ── Has variants: open bottom sheet ────────────────────────────
  Widget _buildVariantButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
              if (!isLoggedIn) {
                _showLoginDialog(context);
                return;
              }
              controller.selectedVariants.clear();
              controller.selectedIndexVariants.clear();
              controller.selectedIndexArray.clear();
              controller.selectedAddOns.clear();
              controller.quantity = 1;
              controller.calculatePrice(productModel);
              productDetailsBottomSheet(context, productModel);
            },
            borderRadius: BorderRadius.circular(rs.btnRadius),
            child: Center(
              child: Text(
                'Add'.tr,
                style: TextStyle(
                  fontSize: rs.btnFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Already in cart: show - qty + ──────────────────────────────
  Widget _buildInCartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrement
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final p = _promo;
                  final finalPrice = p != null
                      ? (p['special_price'] as num).toString()
                      : _priceToPass;
                  final finalDisPrice = p != null ? basePrice : _disPriceToPass;
                  controller.addToCart(
                    productModel: productModel,
                    price: finalPrice,
                    discountPrice: finalDisPrice,
                    isIncrement: false,
                    quantity: _cartQty - 1,
                  );
                },
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(rs.btnRadius),
                  bottomLeft: Radius.circular(rs.btnRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(rs.btnInnerPad),
                  child: Icon(
                    Icons.remove,
                    size: rs.btnIconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Quantity
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rs.qtyHPad),
              child: Text(
                _cartQty.toString(),
                style: TextStyle(
                  fontSize: rs.qtyFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            // Increment
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
                  if (!isLoggedIn) {
                    _showLoginDialog(context);
                    return;
                  }
                  final currentQty = _cartQty;
                  if (currentQty <= (productModel.quantity ?? 0) ||
                      (productModel.quantity ?? 0) == -1) {
                    final p = _promo;
                    if (p != null) {
                      final isAllowed = controller
                          .isPromotionalItemQuantityAllowed(
                            _productId,
                            productModel.vendorID ?? '',
                            currentQty + 1,
                          );
                      if (!isAllowed) {
                        final limit = controller.getPromotionalItemLimit(
                          _productId,
                          productModel.vendorID ?? '',
                        );
                        ShowToastDialog.showToast(
                          'Maximum $limit items allowed for this promotional offer'
                              .tr,
                        );
                        return;
                      }
                    }
                    final finalPrice = p != null
                        ? (p['special_price'] as num).toString()
                        : _priceToPass;
                    final finalDisPrice = p != null
                        ? basePrice
                        : _disPriceToPass;
                    controller.addToCart(
                      productModel: productModel,
                      price: finalPrice,
                      discountPrice: finalDisPrice,
                      isIncrement: true,
                      quantity: currentQty + 1,
                    );
                  } else {
                    ShowToastDialog.showToast('Out of stock'.tr);
                  }
                },
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(rs.btnRadius),
                  bottomRight: Radius.circular(rs.btnRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(rs.btnInnerPad),
                  child: Icon(
                    Icons.add,
                    size: rs.btnIconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Not in cart: simple Add button ─────────────────────────────
  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
              if (!isLoggedIn) {
                _showLoginDialog(context);
                return;
              }
              controller.addProductAndRemoveProductFunction(
                productModel: productModel,
                price: _priceToPass,
                disPrice: _disPriceToPass,
              );
            },
            borderRadius: BorderRadius.circular(rs.btnRadius),
            child: Center(
              child: Text(
                'Add'.tr,
                style: TextStyle(
                  fontSize: rs.btnFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
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
        img: Image.asset(
          'assets/images/ic_launcher.png',
          height: 50,
          width: 50,
        ),
      ),
    );
  }
}

// ── Helpers (keep as top-level, no closures needed) ───────────────

productDetailsBottomSheet(BuildContext context, ProductModel productModel) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: StatefulBuilder(
        builder: (context1, setState) =>
            ProductDetailsView(productModel: productModel),
      ),
    ),
  );
}

infoDialog(RestaurantDetailsProvider controller, ProductModel productModel) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.all(10),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    backgroundColor: AppThemeData.surface,
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Food Information's".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                productModel.description.toString(),
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontWeight: FontWeight.w400,
                  color: AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 20),
              RoundedButtonFill(
                title: 'Back'.tr,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () async => Get.back(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── No products empty state ───────────────────────────────────────

Widget _buildNoProductsMessage(BuildContext context, _RS rs) {
  return Container(
    padding: EdgeInsets.symmetric(
      vertical: rs.emptyVPad,
      horizontal: rs.emptyHPad,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.restaurant_menu_outlined,
          size: rs.emptyIconSize,
          color: AppThemeData.grey600,
        ),
        SizedBox(height: rs.emptyTitleGap),
        Text(
          'No products available here'.tr,
          style: TextStyle(
            fontSize: rs.emptyTitleSize,
            fontWeight: FontWeight.w600,
            color: AppThemeData.grey700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: rs.emptySubGap),
        Text(
          "This restaurant doesn't have any items in their menu right now.".tr,
          style: TextStyle(
            fontSize: rs.emptySubSize,
            color: AppThemeData.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
