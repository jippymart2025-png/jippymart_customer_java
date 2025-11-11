import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restaurant_without_categories_wiget.dart';

import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_product_details_view.dart';
import 'package:jippymart_customer/constant/constant.dart'
    show Constant, cartItem;
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/favourite_item_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/special_price_badge.dart';
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

                    // Get or create the key for this category
                    final categoryKey = controller.getCategoryKey(index);
                    if (!controller.categoryKeys.containsKey(categoryKey)) {
                      controller.categoryKeys[categoryKey] = GlobalKey();
                    }

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
      // Keep categories expanded by default
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

    return ListView.builder(
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, productIndex) {
        ProductModel productModel = products[productIndex];
        return _buildProductItem(
          productModel,
          context,
          vendorCategoryModel,
          productIndex,
          controller,
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
    ProductModel productModel = controller.getProductsByCategory(
      vendorCategoryModel.id.toString(),
    )[index];
    bool isItemAvailable = productModel.isAvailable ?? true;
    String price = "0.0";
    String disPrice = "0.0";
    List<String> selectedVariants = [];
    List<String> selectedIndexVariants = [];
    List<String> selectedIndexArray = [];
    if (productModel.itemAttribute != null) {
      if (productModel.itemAttribute!.attributes!.isNotEmpty) {
        for (var element in productModel.itemAttribute!.attributes!) {
          if (element.attributeOptions!.isNotEmpty) {
            selectedVariants.add(
              productModel
                  .itemAttribute!
                  .attributes![productModel.itemAttribute!.attributes!.indexOf(
                    element,
                  )]
                  .attributeOptions![0]
                  .toString(),
            );
            selectedIndexVariants.add(
              '${productModel.itemAttribute!.attributes!.indexOf(element)} _${productModel.itemAttribute!.attributes![0].attributeOptions![0].toString()}',
            );
            selectedIndexArray.add(
              '${productModel.itemAttribute!.attributes!.indexOf(element)}_0',
            );
          }
        }
      }
      if (productModel.itemAttribute!.variants!
          .where((element) => element.variantSku == selectedVariants.join('-'))
          .isNotEmpty) {
        price = Constant.productCommissionPrice(
          controller.vendorModel,
          productModel.itemAttribute!.variants!
                  .where(
                    (element) =>
                        element.variantSku == selectedVariants.join('-'),
                  )
                  .first
                  .variantPrice ??
              '0',
        );
        disPrice = "0";
      }
    } else {
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
                    FutureBuilder<Map<String, dynamic>?>(
                      future: FireStoreUtils.getActivePromotionForProduct(
                        productId: productModel.id ?? '',
                        restaurantId: productModel.vendorID ?? '',
                      ),
                      builder: (context, promoSnapshot) {
                        if (promoSnapshot.data != null) {
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
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // **FIXED: Use cached promotional data instead of direct Firebase query**
                    Builder(
                      builder: (context) {
                        final promo = controller.getActivePromotionForProduct(
                          productId: productModel.id ?? '',
                          restaurantId: productModel.vendorID ?? '',
                        );
                        final hasPromo = promo != null;
                        final promoPrice = hasPromo
                            ? (promo['special_price'] as num).toString()
                            : null;

                        if (hasPromo) {
                          // Special promotional price display
                          return Row(
                            children: [
                              Flexible(
                                child: Text(
                                  Constant.amountShow(amount: promoPrice!),
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
                              // Show original price with strikethrough
                              Flexible(
                                child: Text(
                                  Constant.amountShow(
                                    amount: Constant.productCommissionPrice(
                                      controller.vendorModel,
                                      productModel.price.toString(),
                                    ),
                                  ),
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
                        } else if (double.parse(disPrice) <= 0) {
                          // Normal price display
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
                                  Constant.amountShow(amount: disPrice),
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
                const SizedBox(height: 5),
                Visibility(
                  visible: false,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return infoDialog(controller, productModel);
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppThemeData.secondary300,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Info".tr,
                          maxLines: 2,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 16,
                            color: AppThemeData.secondary300,
                            fontFamily: AppThemeData.regular,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
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
              // **FIXED: Special promotional price badge using cached data**
              Builder(
                builder: (context) {
                  final promo = controller.getActivePromotionForProduct(
                    productId: productModel.id ?? '',
                    restaurantId: productModel.vendorID ?? '',
                  );

                  print(
                    '[DEBUG] Product ${productModel.id} - Promotion data: $promo',
                  );
                  if (promo != null) {
                    print(
                      '[DEBUG] Showing SPECIAL badge for product ${productModel.id}',
                    );
                    print(
                      '[DEBUG] Badge will be rendered with black background and white text',
                    );
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
                    final userId = await SqlStorageConst.getFirebaseId();
                    if (controller.favouriteItemList
                        .where((p0) => p0.productId == productModel.id)
                        .isNotEmpty) {
                      FavouriteItemModel favouriteModel = FavouriteItemModel(
                        productId: productModel.id,
                        storeId: controller.vendorModel.id,
                        userId: userId,
                      );
                      controller.favouriteItemList.removeWhere(
                        (item) => item.productId == productModel.id,
                      );
                      await FireStoreUtils.removeFavouriteItem(favouriteModel);
                    } else {
                      FavouriteItemModel favouriteModel = FavouriteItemModel(
                        productId: productModel.id,
                        storeId: controller.vendorModel.id,
                        userId: userId,
                      );
                      controller.favouriteItemList.add(favouriteModel);

                      await FireStoreUtils.setFavouriteItem(favouriteModel);
                    }
                  },
                  child: Obx(
                    () =>
                        controller.favouriteItemList
                            .where((p0) => p0.productId == productModel.id)
                            .isNotEmpty
                        ? SvgPicture.asset("assets/icons/ic_like_fill.svg")
                        : SvgPicture.asset("assets/icons/ic_like.svg"),
                  ),
                ),
              ),
              !controller.canAcceptOrders() || Constant.userModel == null
                  ? const SizedBox()
                  : Positioned(
                      bottom: 10,
                      left: 20,
                      right: 20,
                      child: isItemAvailable
                          ? selectedVariants.isNotEmpty ||
                                    (productModel.addOnsTitle != null &&
                                        productModel.addOnsTitle!.isNotEmpty)
                                ? RoundedButtonFill(
                                    title: "Add".tr,
                                    width: 10,
                                    height: 4,
                                    color: AppThemeData.grey50,
                                    textColor: AppThemeData.primary300,
                                    onPress: () async {
                                      controller.selectedVariants.clear();
                                      controller.selectedIndexVariants.clear();
                                      controller.selectedIndexArray.clear();
                                      controller.selectedAddOns.clear();
                                      controller.quantity.value = 1;
                                      if (productModel.itemAttribute != null) {
                                        if (productModel
                                            .itemAttribute!
                                            .attributes!
                                            .isNotEmpty) {
                                          for (var element
                                              in productModel
                                                  .itemAttribute!
                                                  .attributes!) {
                                            if (element
                                                .attributeOptions!
                                                .isNotEmpty) {
                                              controller.selectedVariants.add(
                                                productModel
                                                    .itemAttribute!
                                                    .attributes![productModel
                                                        .itemAttribute!
                                                        .attributes!
                                                        .indexOf(element)]
                                                    .attributeOptions![0]
                                                    .toString(),
                                              );
                                              controller.selectedIndexVariants.add(
                                                '${productModel.itemAttribute!.attributes!.indexOf(element)} _${productModel.itemAttribute!.attributes![0].attributeOptions![0].toString()}',
                                              );
                                              controller.selectedIndexArray.add(
                                                '${productModel.itemAttribute!.attributes!.indexOf(element)}_0',
                                              );
                                            }
                                          }
                                        }
                                        final bool
                                        productIsInList = cartItem.any(
                                          (product) =>
                                              product.id ==
                                              "${productModel.id}~${productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).isNotEmpty ? productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).first.variantId.toString() : ""}",
                                        );
                                        if (productIsInList) {
                                          CartProductModel
                                          element = cartItem.firstWhere(
                                            (product) =>
                                                product.id ==
                                                "${productModel.id}~${productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).isNotEmpty ? productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).first.variantId.toString() : ""}",
                                          );
                                          controller.quantity.value =
                                              element.quantity!;
                                          if (element.extras != null) {
                                            for (var element
                                                in element.extras!) {
                                              controller.selectedAddOns.add(
                                                element,
                                              );
                                            }
                                          }
                                        }
                                      } else {
                                        if (cartItem
                                            .where(
                                              (product) =>
                                                  product.id ==
                                                  "${productModel.id}",
                                            )
                                            .isNotEmpty) {
                                          CartProductModel element = cartItem
                                              .firstWhere(
                                                (product) =>
                                                    product.id ==
                                                    "${productModel.id}",
                                              );
                                          controller.quantity.value =
                                              element.quantity!;
                                          if (element.extras != null) {
                                            for (var element
                                                in element.extras!) {
                                              controller.selectedAddOns.add(
                                                element,
                                              );
                                            }
                                          }
                                        }
                                      }

                                      controller.calculatePrice(productModel);
                                      productDetailsBottomSheet(
                                        context,
                                        productModel,
                                      );
                                    },
                                  )
                                : Obx(
                                    () =>
                                        cartItem
                                            .where(
                                              (p0) => p0.id == productModel.id,
                                            )
                                            .isNotEmpty
                                        ? Container(
                                            width: Responsive.width(
                                              100,
                                              context,
                                            ),
                                            height: Responsive.height(
                                              4,
                                              context,
                                            ),
                                            decoration: ShapeDecoration(
                                              color: AppThemeData.grey50,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(200),
                                              ),
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  InkWell(
                                                    onTap: () async {
                                                      // Check for promotional price
                                                      final promo =
                                                          await FireStoreUtils.getActivePromotionForProduct(
                                                            productId:
                                                                productModel
                                                                    .id ??
                                                                '',
                                                            restaurantId:
                                                                productModel
                                                                    .vendorID ??
                                                                '',
                                                          );

                                                      String finalPrice = price;
                                                      String
                                                      finalDiscountPrice =
                                                          disPrice;

                                                      if (promo != null) {
                                                        // Use promotional price
                                                        finalPrice =
                                                            (promo['special_price']
                                                                    as num)
                                                                .toString();
                                                        finalDiscountPrice =
                                                            Constant.productCommissionPrice(
                                                              controller
                                                                  .vendorModel,
                                                              productModel.price
                                                                  .toString(),
                                                            ); // original price for strikethrough
                                                      }

                                                      controller.addToCart(
                                                        productModel:
                                                            productModel,
                                                        price: finalPrice,
                                                        discountPrice:
                                                            finalDiscountPrice,
                                                        isIncrement: false,
                                                        quantity:
                                                            cartItem
                                                                .where(
                                                                  (p0) =>
                                                                      p0.id ==
                                                                      productModel
                                                                          .id,
                                                                )
                                                                .first
                                                                .quantity! -
                                                            1,
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.remove,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                        ),
                                                    child: Text(
                                                      cartItem
                                                          .where(
                                                            (p0) =>
                                                                p0.id ==
                                                                productModel.id,
                                                          )
                                                          .first
                                                          .quantity
                                                          .toString(),
                                                      textAlign:
                                                          TextAlign.start,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily:
                                                            AppThemeData.medium,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppThemeData
                                                            .grey800,
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      if ((cartItem
                                                                      .where(
                                                                        (p0) =>
                                                                            p0.id ==
                                                                            productModel.id,
                                                                      )
                                                                      .first
                                                                      .quantity ??
                                                                  0) <=
                                                              (productModel
                                                                      .quantity ??
                                                                  0) ||
                                                          (productModel
                                                                      .quantity ??
                                                                  0) ==
                                                              -1) {
                                                        // Check for promotional price and limit
                                                        final promo =
                                                            await FireStoreUtils.getActivePromotionForProduct(
                                                              productId:
                                                                  productModel
                                                                      .id ??
                                                                  '',
                                                              restaurantId:
                                                                  productModel
                                                                      .vendorID ??
                                                                  '',
                                                            );

                                                        // Check promotional item limit using new helper method
                                                        if (promo != null) {
                                                          final isAllowed = controller.isPromotionalItemQuantityAllowed(
                                                            productModel.id ??
                                                                '',
                                                            productModel
                                                                    .vendorID ??
                                                                '',
                                                            cartItem
                                                                    .where(
                                                                      (p0) =>
                                                                          p0.id ==
                                                                          productModel
                                                                              .id,
                                                                    )
                                                                    .first
                                                                    .quantity! +
                                                                1,
                                                          );

                                                          if (!isAllowed) {
                                                            final limit = controller
                                                                .getPromotionalItemLimit(
                                                                  productModel
                                                                          .id ??
                                                                      '',
                                                                  productModel
                                                                          .vendorID ??
                                                                      '',
                                                                );
                                                            ShowToastDialog.showToast(
                                                              "Maximum $limit items allowed for this promotional offer"
                                                                  .tr,
                                                            );
                                                            return;
                                                          }
                                                        }

                                                        String finalPrice =
                                                            price;
                                                        String
                                                        finalDiscountPrice =
                                                            disPrice;

                                                        if (promo != null) {
                                                          // Use promotional price
                                                          finalPrice =
                                                              (promo['special_price']
                                                                      as num)
                                                                  .toString();
                                                          finalDiscountPrice =
                                                              Constant.productCommissionPrice(
                                                                controller
                                                                    .vendorModel,
                                                                productModel
                                                                    .price
                                                                    .toString(),
                                                              ); // original price for strikethrough
                                                        }

                                                        controller.addToCart(
                                                          productModel:
                                                              productModel,
                                                          price: finalPrice,
                                                          discountPrice:
                                                              finalDiscountPrice,
                                                          isIncrement: true,
                                                          quantity:
                                                              cartItem
                                                                  .where(
                                                                    (p0) =>
                                                                        p0.id ==
                                                                        productModel
                                                                            .id,
                                                                  )
                                                                  .first
                                                                  .quantity! +
                                                              1,
                                                        );
                                                      } else {
                                                        ShowToastDialog.showToast(
                                                          "Out of stock".tr,
                                                        );
                                                      }
                                                    },
                                                    child: const Icon(
                                                      Icons.add,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : RoundedButtonFill(
                                            title: "Add".tr,
                                            width: 10,
                                            height: 4,
                                            color: AppThemeData.grey50,
                                            textColor: AppThemeData.primary300,
                                            onPress: () async {
                                              if (1 <=
                                                      (productModel.quantity ??
                                                          0) ||
                                                  (productModel.quantity ??
                                                          0) ==
                                                      -1) {
                                                // Check for promotional price (ULTRA-FAST - ZERO ASYNC)
                                                final promo = controller
                                                    .getActivePromotionForProduct(
                                                      productId:
                                                          productModel.id ?? '',
                                                      restaurantId:
                                                          productModel
                                                              .vendorID ??
                                                          '',
                                                    );

                                                String finalPrice = price;
                                                String finalDiscountPrice =
                                                    disPrice;

                                                if (promo != null) {
                                                  // Use promotional price
                                                  finalPrice =
                                                      (promo['special_price']
                                                              as num)
                                                          .toString();
                                                  finalDiscountPrice =
                                                      Constant.productCommissionPrice(
                                                        controller.vendorModel,
                                                        productModel.price
                                                            .toString(),
                                                      ); // original price for strikethrough
                                                }
                                                controller.addToCart(
                                                  productModel: productModel,
                                                  price: finalPrice,
                                                  discountPrice:
                                                      finalDiscountPrice,
                                                  isIncrement: true,
                                                  quantity: 1,
                                                );
                                              } else {
                                                ShowToastDialog.showToast(
                                                  "Out of stock".tr,
                                                );
                                              }
                                            },
                                          ),
                                  )
                          : const SizedBox(), // Removed the grey button completely
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

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
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Gram".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    productModel.grams.toString(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      color: AppThemeData.grey900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Calories".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    productModel.calories.toString(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      color: AppThemeData.grey900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Proteins".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    productModel.proteins.toString(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      color: AppThemeData.grey900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Fats".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.grey600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    productModel.fats.toString(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      color: AppThemeData.grey900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              productModel.productSpecification != null &&
                      productModel.productSpecification!.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Specification".tr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.grey900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ListView.builder(
                          itemCount: productModel.productSpecification!.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productModel.productSpecification!.keys
                                        .elementAt(index),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.regular,
                                      color: AppThemeData.grey600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    productModel.productSpecification!.values
                                        .elementAt(index),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.bold,
                                      color: AppThemeData.grey900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : const SizedBox(),
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
