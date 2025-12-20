import 'dart:developer';

import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restaurant_without_categories_wiget.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_product_details_view.dart';
import 'package:jippymart_customer/constant/constant.dart' show Constant;
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/widget/special_price_badge.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../constant/show_toast_dialog.dart';

class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        return Container(
          color: AppThemeData.grey50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: controller.productList.isEmpty
              ? _buildNoProductsMessage(context)
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
                    VendorCategoryModel vendorCategoryModel =
                        controller.vendorCategoryList[index];
                    String? categoryKey = controller.returnKeyCategories(
                      index: index,
                    );
                    return KeyedSubtree(
                      key: controller.categoryKeys[categoryKey],
                      child: _buildCategoryExpansionTile(
                        context,
                        vendorCategoryModel,
                        index,
                        controller,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildCategoryExpansionTile(
    BuildContext context,
    VendorCategoryModel vendorCategoryModel,
    int index,
    RestaurantDetailsProvider controller,
  ) {
    return ExpansionTile(
      childrenPadding: EdgeInsets.zero,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      initiallyExpanded: true,
      onExpansionChanged: (expanded) {
        if (expanded) {
          print("Category ${vendorCategoryModel.title} expanded");
        }
      },
      title: Text(
        "${vendorCategoryModel.title.toString()} (${controller.getProductsByCategory(vendorCategoryModel.id.toString()).length})",
        style: TextStyle(
          fontSize: 18,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w600,
          color: AppThemeData.grey900,
        ),
      ),
      children: [
        Consumer<RestaurantDetailsProvider>(
          builder: (context, controller, _) => _buildProductsForCategory(
            vendorCategoryModel,
            context,
            controller,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsForCategory(
    VendorCategoryModel vendorCategoryModel,
    BuildContext context,
    RestaurantDetailsProvider controller,
  ) {
    final products = controller.getProductsByCategory(
      vendorCategoryModel.id.toString(),
    );
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        return ListView.builder(
          itemCount: products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemBuilder: (context, productIndex) {
            ProductModel productModel = products[productIndex];
            log(productModel.id.toString(), name: " productsLength");
            return _buildProductItem(
              productModel,
              context,
              vendorCategoryModel,
              productIndex,
              controller,
            );
          },
        );
      },
    );
  }

  Widget _buildProductItem(
    ProductModel productModel,
    BuildContext context,
    VendorCategoryModel vendorCategoryModel,
    int index,
    RestaurantDetailsProvider controller,
  ) {
    bool isItemAvailable = productModel.isAvailable ?? true;
    String price = "0.0";
    String disPrice = "0.0";
    // Calculate prices - FIXED VERSION
    if (productModel.itemAttribute != null &&
        productModel.itemAttribute!.variants != null &&
        productModel.itemAttribute!.variants!.isNotEmpty) {
      // If no variant is selected yet, use the first variant as default
      if (controller.selectedVariants.isEmpty) {
        // Use the first variant's price as default
        final firstVariant = productModel.itemAttribute!.variants!.first;
        price = Constant.productCommissionPrice(
          controller.vendorModel,
          firstVariant.variantPrice ?? '0',
        );
        disPrice = "0";
      } else {
        // Use the selected variant's price
        final selectedVariant = productModel.itemAttribute!.variants!
            .firstWhere(
              (element) =>
                  element.variantSku == controller.selectedVariants.join('-'),
              orElse: () => productModel.itemAttribute!.variants!.first,
            );
        price = Constant.productCommissionPrice(
          controller.vendorModel,
          selectedVariant.variantPrice ?? '0',
        );
        disPrice = "0";
      }
    } else {
      // Regular product without variants
      price = Constant.productCommissionPrice(
        controller.vendorModel,
        productModel.price.toString(),
      );
      disPrice = double.parse(productModel.disPrice.toString()) <= 0
          ? "0"
          : Constant.productCommissionPrice(
              controller.vendorModel,
              productModel.disPrice.toString(),
            );
    }
    // if (productModel.itemAttribute != null) {
    //   if (productModel.itemAttribute!.variants!
    //       .where(
    //         (element) =>
    //             element.variantSku == controller.selectedVariants.join('-'),
    //       )
    //       .isNotEmpty) {
    //     price = Constant.productCommissionPrice(
    //       controller.vendorModel,
    //       productModel.itemAttribute!.variants!
    //               .where(
    //                 (element) =>
    //                     element.variantSku ==
    //                     controller.selectedVariants.join('-'),
    //               )
    //               .first
    //               .variantPrice ??
    //           '0',
    //     );
    //     disPrice = "0";
    //   }
    // } else {
    //   price = Constant.productCommissionPrice(
    //     controller.vendorModel,
    //     productModel.price.toString(),
    //   );
    //   disPrice = double.parse(productModel.disPrice.toString()) <= 0
    //       ? "0"
    //       : Constant.productCommissionPrice(
    //           controller.vendorModel,
    //           productModel.disPrice.toString(),
    //         );
    // }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    productModel.nonveg == true
                        ? SvgPicture.asset("assets/icons/ic_nonveg.svg")
                        : SvgPicture.asset("assets/icons/ic_veg.svg"),
                    const SizedBox(width: 5),
                    Text(
                      productModel.nonveg == true
                          ? "Non Veg.".tr
                          : "Pure veg.".tr,
                      style: TextStyle(
                        color: productModel.nonveg == true
                            ? AppThemeData.danger300
                            : AppThemeData.success400,
                        fontFamily: AppThemeData.semiBold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        productModel.name.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppThemeData.grey900,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final productId = productModel.id?.toString() ?? '';
                        final restaurantId = productModel.vendorID ?? '';
                        if (productId.isNotEmpty && restaurantId.isNotEmpty) {
                          final promo = controller.getActivePromotionForProduct(
                            productId: productId,
                            restaurantId: restaurantId,
                          );
                          print(
                            "controller.getActivePromotionForProduct for $productId: $promo ",
                          );
                          if (promo != null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SPECIAL OFFER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price display
                    Builder(
                      builder: (context) {
                        final promo = controller.getActivePromotionForProduct(
                          productId: productModel.id?.toString() ?? '',
                          restaurantId: productModel.vendorID ?? '',
                        );
                        final hasPromo = promo != null;

                        if (hasPromo) {
                          final promoPrice = (promo['special_price'] as num)
                              .toString();
                          return Row(
                            children: [
                              //finded
                              Flexible(
                                child: Text(
                                  Constant.amountShow(amount: promoPrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppThemeData.grey900,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  // Show the calculated price (which includes variant pricing) as original
                                  Constant.amountShow(amount: price),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
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
                        // final promo = controller.getActivePromotionForProduct(
                        //   productId: productModel.id?.toString() ?? '',
                        //   restaurantId: productModel.vendorID ?? '',
                        // );
                        // final hasPromo = promo != null;
                        // final promoPrice = hasPromo
                        //     ? (promo['special_price'] as num).toString()
                        //     : null;
                        // if (hasPromo) {
                        //   // Special promotional price display
                        //   return Row(
                        //     children: [
                        //       Flexible(
                        //         child: Text(
                        //           Constant.amountShow(amount: promoPrice!),
                        //           maxLines: 1,
                        //           overflow: TextOverflow.ellipsis,
                        //           style: TextStyle(
                        //             fontSize: 16,
                        //             color: AppThemeData.grey900,
                        //             fontFamily: AppThemeData.semiBold,
                        //             fontWeight: FontWeight.w600,
                        //           ),
                        //         ),
                        //       ),
                        //       const SizedBox(width: 5),
                        //       // Show original price with strikethrough
                        //       Flexible(
                        //         child: Text(
                        //           Constant.amountShow(
                        //             amount: Constant.productCommissionPrice(
                        //               controller.vendorModel,
                        //               productModel.price.toString(),
                        //             ),
                        //           ),
                        //           maxLines: 1,
                        //           overflow: TextOverflow.ellipsis,
                        //           style: TextStyle(
                        //             fontSize: 14,
                        //             decoration: TextDecoration.lineThrough,
                        //             decorationColor: AppThemeData.grey300,
                        //             color: AppThemeData.grey300,
                        //             fontFamily: AppThemeData.semiBold,
                        //             fontWeight: FontWeight.w600,
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   );
                        // }
                        else if (double.parse(disPrice) <= 0) {
                          // Normal price display
                          // return SizedBox();
                          return Text(
                            Constant.amountShow(amount: price),
                            style: TextStyle(
                              fontSize: 16,
                              color: AppThemeData.grey900,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        } else {
                          // Regular discount price display
                          return Row(
                            children: [
                              Flexible(
                                child: Text(
                                  Constant.amountShow(
                                    amount: disPrice.toString(),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppThemeData.grey900,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  Constant.amountShow(amount: price),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
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
                      },
                    ),
                    if (!isItemAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Not Available",
                          style: TextStyle(
                            color: Colors.red,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/ic_star.svg",
                      colorFilter: const ColorFilter.mode(
                        AppThemeData.warning300,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${Constant.calculateReview(reviewCount: productModel.reviewsCount!.toStringAsFixed(0), reviewSum: productModel.reviewsSum.toString())} (${productModel.reviewsCount!.toStringAsFixed(0)})",
                      style: TextStyle(
                        color: AppThemeData.grey900,
                        fontFamily: AppThemeData.regular,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${productModel.description}",
                  maxLines: 2,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: AppThemeData.grey900,
                    fontFamily: AppThemeData.regular,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
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
                    fit: BoxFit.cover,
                    height: Responsive.height(16, context),
                    width: Responsive.width(34, context),
                  ),
                ),
              ),
              // Special promotional price badge
              Builder(
                builder: (context) {
                  final promo = controller.getActivePromotionForProduct(
                    productId: productModel.id?.toString() ?? '',
                    restaurantId: productModel.vendorID ?? '',
                  );

                  if (promo != null) {
                    return Positioned(
                      top: 0,
                      left: 0,
                      child: const SpecialPriceBadge(
                        showShimmer: true,
                        width: 60,
                        height: 60,
                        margin: EdgeInsets.zero,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (!isItemAvailable)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              Positioned(
                right: 10,
                top: 10,
                child: InkWell(
                  onTap: () async {
                    if (productModel.id == null ||
                        productModel.id.toString().isEmpty) {
                      ShowToastDialog.showToast("Invalid product data");
                      return;
                    }
                    try {
                      await controller.toggleProductFavorite(
                        productModel.id!.toString(),
                      );
                    } catch (e) {
                      ShowToastDialog.showToast("Failed to update favorites");
                    }
                  },
                  child:
                      controller.isProductFavorite(productModel.id.toString())
                      ? SvgPicture.asset("assets/icons/ic_like_fill.svg")
                      : SvgPicture.asset("assets/icons/ic_like.svg"),
                ),
              ),
              !controller.canAcceptOrders()
                  ? const SizedBox()
                  : Positioned(
                      bottom: 10,
                      left: 20,
                      right: 20,
                      child: isItemAvailable
                          ? _buildAddToCartButton(
                              controller,
                              productModel,
                              price,
                              disPrice,
                            )
                          : const SizedBox(),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(
    RestaurantDetailsProvider controller,
    ProductModel productModel,
    String price,
    String disPrice,
  ) {
    final productId = productModel.id?.toString() ?? '';
    final hasVariantsOrAddons =
        controller.selectedVariants.isNotEmpty ||
        (productModel.addOnsTitle != null &&
            productModel.addOnsTitle!.isNotEmpty);
    // Fix: Handle variant IDs (format: "productId~variantId" or just "productId")
    final isInCart = HomeProvider.cartItem.any((cartItem) {
      if (cartItem.id == null || cartItem.id!.isEmpty) return false;
      // Check exact match or if cart item ID starts with productId~
      // This handles both simple products and products with variants
      return cartItem.id == productId || cartItem.id!.startsWith('$productId~');
    });
    print(
      " isInCart $isInCart for productId: $productId, cartItem IDs: ${HomeProvider.cartItem.map((e) => e.id).toList()}",
    );
    if (hasVariantsOrAddons) {
      return RoundedButtonFill(
        title: "Add".tr,
        width: 10,
        height: 4,
        color: AppThemeData.grey50,
        textColor: AppThemeData.primary300,
        onPress: () async {
          // Check if user is logged in
          final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
          if (!isLoggedIn) {
            _showLoginRequiredDialog(Get.context!);
            return;
          }
          controller.selectedVariants.clear();
          controller.selectedIndexVariants.clear();
          controller.selectedIndexArray.clear();
          controller.selectedAddOns.clear();
          controller.quantity = 1;
          controller.calculatePrice(productModel);
          productDetailsBottomSheet(Get.context!, productModel);
        },
      );
    } else if (isInCart) {
      return Container(
        width: Responsive.width(100, Get.context!),
        height: Responsive.height(4, Get.context!),
        decoration: ShapeDecoration(
          color: AppThemeData.grey50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                // Use cached promotional data for instant response
                final promo = controller.getActivePromotionForProduct(
                  productId: productId,
                  restaurantId: productModel.vendorID ?? '',
                );
                String finalPrice = price;
                String finalDiscountPrice = disPrice;

                if (promo != null) {
                  // Use promotional price
                  finalPrice = (promo['special_price'] as num).toString();
                  finalDiscountPrice = Constant.productCommissionPrice(
                    controller.vendorModel,
                    productModel.price.toString(),
                  );
                }
                controller.addToCart(
                  productModel: productModel,
                  price: finalPrice,
                  discountPrice: finalDiscountPrice,
                  isIncrement: false,
                  quantity: _findCartItemQuantity(productId) - 1,
                );
              },
              child: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                _findCartItemQuantity(productId).toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w500,
                  color: AppThemeData.grey800,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                // Check if user is logged in
                final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
                if (!isLoggedIn) {
                  _showLoginRequiredDialog(Get.context!);
                  return;
                }
                final currentQty = _findCartItemQuantity(productId);
                if ((currentQty) <= (productModel.quantity ?? 0) ||
                    (productModel.quantity ?? 0) == -1) {
                  // Use cached promotional data for instant response
                  final promo = controller.getActivePromotionForProduct(
                    productId: productId,
                    restaurantId: productModel.vendorID ?? '',
                  );
                  // Check promotional item limit (cached)
                  if (promo != null) {
                    final isAllowed = controller
                        .isPromotionalItemQuantityAllowed(
                          productId,
                          productModel.vendorID ?? '',
                          currentQty + 1,
                        );

                    if (!isAllowed) {
                      final limit = controller.getPromotionalItemLimit(
                        productId,
                        productModel.vendorID ?? '',
                      );
                      ShowToastDialog.showToast(
                        "Maximum $limit items allowed for this promotional offer"
                            .tr,
                      );
                      return;
                    }
                  }

                  String finalPrice = price;
                  String finalDiscountPrice = disPrice;
                  if (promo != null) {
                    finalPrice = (promo['special_price'] as num).toString();
                    finalDiscountPrice = Constant.productCommissionPrice(
                      controller.vendorModel,
                      productModel.price.toString(),
                    );
                  }
                  controller.addToCart(
                    productModel: productModel,
                    price: finalPrice,
                    discountPrice: finalDiscountPrice,
                    isIncrement: true,
                    quantity: currentQty + 1,
                  );
                } else {
                  ShowToastDialog.showToast("Out of stock".tr);
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      );
    } else {
      // Optimized: Direct call without async overhead
      return RoundedButtonFill(
        title: "Add".tr,
        width: 10,
        height: 4,
        color: AppThemeData.grey50,
        textColor: AppThemeData.primary300,
        onPress: () async {
          // Check if user is logged in
          final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
          if (!isLoggedIn) {
            _showLoginRequiredDialog(Get.context!);
            return;
          }
          // Non-blocking call - UI updates immediately
          controller.addProductAndRemoveProductFunction(
            productModel: productModel,
            price: price,
            disPrice: disPrice,
          );
        },
      );
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Login Required".tr,
          descriptions:
              "Please login to add items to your cart and continue shopping."
                  .tr,
          positiveString: "Login".tr,
          negativeString: "Cancel".tr,
          positiveClick: () {
            Get.back(); // Close dialog
            Get.to(() => const PhoneNumberScreen());
          },
          negativeClick: () {
            Get.back(); // Close dialog
          },
          img: Image.asset(
            'assets/images/ic_launcher.png',
            height: 50,
            width: 50,
          ),
        );
      },
    );
  }

  int _findCartItemQuantity(String productId) {
    if (productId.isEmpty) return 0;

    // Find all matching items (exact match or variant IDs starting with productId~)
    final matchingItems = HomeProvider.cartItem.where((cartItem) {
      if (cartItem.id == null || cartItem.id!.isEmpty) return false;
      // Check exact match or if cart item ID starts with productId~
      return cartItem.id == productId || cartItem.id!.startsWith('$productId~');
    }).toList();

    if (matchingItems.isEmpty) return 0;

    // Sum up quantities of all matching items (handles multiple variants)
    return matchingItems.fold<int>(
      0,
      (sum, item) => sum + (item.quantity ?? 0),
    );
  }
}

// Keep your existing helper methods
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
        builder: (context1, setState) {
          return ProductDetailsView(productModel: productModel);
        },
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
                  textAlign: TextAlign.start,
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
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontWeight: FontWeight.w400,
                  color: AppThemeData.grey900,
                ),
              ),
              // ... rest of info dialog content
              const SizedBox(height: 20),
              RoundedButtonFill(
                title: "Back".tr,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () async {
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildNoProductsMessage(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.restaurant_menu_outlined,
          size: 80,
          color: AppThemeData.grey600,
        ),
        const SizedBox(height: 20),
        Text(
          "No products available here".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppThemeData.grey700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "This restaurant doesn't have any items in their menu right now.".tr,
          style: TextStyle(fontSize: 14, color: AppThemeData.grey600),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
