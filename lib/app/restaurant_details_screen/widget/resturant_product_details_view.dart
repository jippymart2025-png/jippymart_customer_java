import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../themes/responsive.dart';
import '../../../utils/network_image_widget.dart';

class ProductDetailsView extends StatelessWidget {
  final ProductModel productModel;

  const ProductDetailsView({super.key, required this.productModel});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        bool isItemAvailable = productModel.isAvailable ?? true;
        return Scaffold(
          backgroundColor: AppThemeData.surface,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: AppThemeData.grey50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(16),
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
                              height: Responsive.height(11, context),
                              width: Responsive.width(22, context),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      productModel.name.toString(),
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                        fontFamily: AppThemeData.semiBold,
                                        fontWeight: FontWeight.w600,
                                        color: AppThemeData.grey900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      await controller.toggleProductFavorite(
                                        productModel.id.toString(),
                                      );
                                    },
                                    child:
                                        controller.isProductFavorite(
                                          productModel.id.toString(),
                                        )
                                        ? SvgPicture.asset(
                                            "assets/icons/ic_like_fill.svg",
                                          )
                                        : SvgPicture.asset(
                                            "assets/icons/ic_like.svg",
                                          ),
                                  ),
                                ],
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
                              Text(
                                productModel.description.toString(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppThemeData.regular,
                                  fontWeight: FontWeight.w400,
                                  color: AppThemeData.grey900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                productModel.itemAttribute == null ||
                        productModel.itemAttribute!.attributes!.isEmpty
                    ? const SizedBox()
                    : ListView.builder(
                        itemCount:
                            productModel.itemAttribute!.attributes!.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          String title = "";
                          for (var element in controller.attributesList) {
                            if (productModel
                                    .itemAttribute!
                                    .attributes![index]
                                    .attributeId ==
                                element.id) {
                              title = element.title.toString();
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            child: Container(
                              decoration: ShapeDecoration(
                                color: AppThemeData.grey50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    productModel
                                            .itemAttribute!
                                            .attributes![index]
                                            .attributeOptions!
                                            .isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontFamily:
                                                        AppThemeData.semiBold,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppThemeData.grey800,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: Text(
                                                  "Required • Select any 1 option"
                                                      .tr,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppThemeData.grey500,
                                                  ),
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                                child: Divider(),
                                              ),
                                            ],
                                          )
                                        : Offstage(),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Wrap(
                                        spacing: 6.0,
                                        runSpacing: 6.0,
                                        children: List.generate(
                                          productModel
                                              .itemAttribute!
                                              .attributes![index]
                                              .attributeOptions!
                                              .length,
                                          (i) {
                                            return InkWell(
                                              onTap: isItemAvailable
                                                  ? () async {
                                                      if (controller
                                                          .selectedIndexVariants
                                                          .where(
                                                            (element) => element
                                                                .contains(
                                                                  '$index _',
                                                                ),
                                                          )
                                                          .isEmpty) {
                                                        controller
                                                            .selectedVariants
                                                            .insert(
                                                              index,
                                                              productModel
                                                                  .itemAttribute!
                                                                  .attributes![index]
                                                                  .attributeOptions![i]
                                                                  .toString(),
                                                            );
                                                        controller
                                                            .selectedIndexVariants
                                                            .add(
                                                              '$index _${productModel.itemAttribute!.attributes![index].attributeOptions![i].toString()}',
                                                            );
                                                        controller
                                                            .selectedIndexArray
                                                            .add('${index}_$i');
                                                      } else {
                                                        controller
                                                            .selectedIndexArray
                                                            .remove(
                                                              '${index}_${productModel.itemAttribute!.attributes![index].attributeOptions?.indexOf(controller.selectedIndexVariants.where((element) => element.contains('$index _')).first.replaceAll('$index _', ''))}',
                                                            );
                                                        controller
                                                            .selectedVariants
                                                            .removeAt(index);
                                                        controller
                                                            .selectedIndexVariants
                                                            .remove(
                                                              controller
                                                                  .selectedIndexVariants
                                                                  .where(
                                                                    (
                                                                      element,
                                                                    ) => element
                                                                        .contains(
                                                                          '$index _',
                                                                        ),
                                                                  )
                                                                  .first,
                                                            );
                                                        controller
                                                            .selectedVariants
                                                            .insert(
                                                              index,
                                                              productModel
                                                                  .itemAttribute!
                                                                  .attributes![index]
                                                                  .attributeOptions![i]
                                                                  .toString(),
                                                            );
                                                        controller
                                                            .selectedIndexVariants
                                                            .add(
                                                              '$index _${productModel.itemAttribute!.attributes![index].attributeOptions![i].toString()}',
                                                            );
                                                        controller
                                                            .selectedIndexArray
                                                            .add('${index}_$i');
                                                      }

                                                      final bool
                                                      productIsInList = HomeProvider
                                                          .cartItem
                                                          .any(
                                                            (product) =>
                                                                product.id ==
                                                                "${productModel.id}~${productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).isNotEmpty ? productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).first.variantId.toString() : ""}",
                                                          );
                                                      if (productIsInList) {
                                                        CartProductModel
                                                        element = HomeProvider
                                                            .cartItem
                                                            .firstWhere(
                                                              (product) =>
                                                                  product.id ==
                                                                  "${productModel.id}~${productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).isNotEmpty ? productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).first.variantId.toString() : ""}",
                                                            );
                                                        controller.quantity =
                                                            element.quantity!;
                                                      } else {
                                                        controller.quantity = 1;
                                                      }

                                                      controller.calculatePrice(
                                                        productModel,
                                                      );
                                                    }
                                                  : null,
                                              child: Chip(
                                                shape:
                                                    const RoundedRectangleBorder(
                                                      side: BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                            Radius.circular(20),
                                                          ),
                                                    ),
                                                label: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      productModel
                                                          .itemAttribute!
                                                          .attributes![index]
                                                          .attributeOptions![i]
                                                          .toString(),
                                                      style: TextStyle(
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily:
                                                            AppThemeData.medium,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            controller
                                                                .selectedVariants
                                                                .contains(
                                                                  productModel
                                                                      .itemAttribute!
                                                                      .attributes![index]
                                                                      .attributeOptions![i]
                                                                      .toString(),
                                                                )
                                                            ? Colors.white
                                                            : AppThemeData
                                                                  .grey300,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    controller.selectedVariants
                                                        .contains(
                                                          productModel
                                                              .itemAttribute!
                                                              .attributes![index]
                                                              .attributeOptions![i]
                                                              .toString(),
                                                        )
                                                    ? AppThemeData.primary300
                                                    : AppThemeData.grey100,
                                                elevation: 6.0,
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                productModel.addOnsTitle == null ||
                        productModel.addOnsTitle!.isEmpty
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        child: Container(
                          decoration: ShapeDecoration(
                            color: AppThemeData.grey50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    "Addons".tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                      color: AppThemeData.grey800,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(),
                                ),
                                ListView.builder(
                                  itemCount: productModel.addOnsTitle!.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    String title =
                                        productModel.addOnsTitle![index];
                                    String price =
                                        productModel.addOnsPrice![index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.start,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 16,
                                                overflow: TextOverflow.ellipsis,
                                                fontFamily: AppThemeData.medium,
                                                fontWeight: FontWeight.w500,
                                                color: AppThemeData.grey800,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            Constant.amountShow(
                                              amount:
                                                  Constant.productCommissionPrice(
                                                    controller.vendorModel,
                                                    price,
                                                  ),
                                            ),
                                            textAlign: TextAlign.start,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 16,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily: AppThemeData.medium,
                                              fontWeight: FontWeight.w500,
                                              color: AppThemeData.grey800,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            height: 24.0,
                                            width: 24.0,
                                            child: Checkbox(
                                              value: controller.selectedAddOns
                                                  .contains(title),
                                              activeColor:
                                                  AppThemeData.primary300,
                                              onChanged: isItemAvailable
                                                  ? (value) {
                                                      if (value != null) {
                                                        if (value == true) {
                                                          controller
                                                              .selectedAddOns
                                                              .add(title);
                                                        } else {
                                                          controller
                                                              .selectedAddOns
                                                              .remove(title);
                                                        }
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            color: AppThemeData.grey100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      width: Responsive.width(100, context),
                      height: Responsive.height(5.5, context),
                      decoration: ShapeDecoration(
                        color: AppThemeData.grey200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: isItemAvailable
                                ? () {
                                    if (controller.quantity > 1) {
                                      controller.quantity -= 1;
                                    }
                                  }
                                : null,
                            child: Icon(
                              Icons.remove,
                              color: isItemAvailable
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              controller.quantity.toString(),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                                color: AppThemeData.grey800,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: isItemAvailable
                                ? () {
                                    final promo = controller
                                        .getActivePromotionForProduct(
                                          productId:
                                              productModel.id.toString() ?? '',
                                          restaurantId:
                                              productModel.vendorID ?? '',
                                        );

                                    if (promo != null) {
                                      final isAllowed = controller
                                          .isPromotionalItemQuantityAllowed(
                                            productModel.id.toString() ?? '',
                                            productModel.vendorID ?? '',
                                            controller.quantity + 1,
                                          );

                                      if (!isAllowed) {
                                        final limit = controller
                                            .getPromotionalItemLimit(
                                              productModel.id.toString() ?? '',
                                              productModel.vendorID ?? '',
                                            );
                                        ShowToastDialog.showToast(
                                          "Maximum $limit items allowed for this promotional offer"
                                              .tr,
                                        );
                                        return;
                                      }
                                    }

                                    if (productModel.itemAttribute == null) {
                                      if (controller.quantity <=
                                              (productModel.quantity ?? 0) ||
                                          (productModel.quantity ?? 0) == -1) {
                                        controller.quantity += 1;
                                      } else {
                                        ShowToastDialog.showToast(
                                          "Out of stock".tr,
                                        );
                                      }
                                    } else {
                                      final matchedVariant = productModel
                                              .itemAttribute!.variants
                                              ?.where(
                                                (element) =>
                                                    element.variantSku ==
                                                    controller
                                                        .selectedVariants
                                                        .join('-'),
                                              );
                                      if (matchedVariant != null &&
                                          matchedVariant.isNotEmpty) {
                                        int totalQuantity = int.parse(
                                          matchedVariant.first
                                              .variantQuantity
                                              .toString(),
                                        );
                                        if (controller.quantity <=
                                                totalQuantity ||
                                            totalQuantity == -1) {
                                          controller.quantity += 1;
                                        } else {
                                          ShowToastDialog.showToast(
                                            "Out of stock".tr,
                                          );
                                        }
                                      }
                                    }
                                  }
                                : null,
                            child: Icon(
                              Icons.add,
                              color: isItemAvailable
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: Responsive.height(5.5, context),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(200),
                          ),
                        ),
                        onPressed: isItemAvailable
                            ? () async {
                                if (productModel.itemAttribute != null &&
                                    productModel.itemAttribute!.attributes !=
                                        null &&
                                    productModel.itemAttribute!.attributes!
                                        .isNotEmpty) {
                                  if (controller.selectedVariants.isEmpty ||
                                      controller.selectedVariants
                                          .any((v) => v.isEmpty)) {
                                    ShowToastDialog.showToast(
                                      'Please select all variant options'.tr,
                                    );
                                    return;
                                  }

                                  final matchedVariants = productModel
                                          .itemAttribute!.variants
                                          ?.where(
                                            (v) =>
                                                v.variantSku ==
                                                controller.selectedVariants
                                                    .join('-'),
                                          )
                                          .toList();

                                  if (matchedVariants == null ||
                                      matchedVariants.isEmpty) {
                                    ShowToastDialog.showToast(
                                      'Invalid variant selection'.tr,
                                    );
                                    return;
                                  }

                                  final matched = matchedVariants.first;

                                  final variantInfo = VariantInfo(
                                    variantId: matched.variantId ?? '',
                                    variantPrice:
                                        matched.variantPrice ?? '0',
                                    variantSku:
                                        matched.variantSku ?? '',
                                    variantImage: matched.variantImage,
                                    variantOptions: {
                                      'option': controller
                                          .selectedVariants
                                          .join('-'),
                                      'merchant_price':
                                          matched.variantPrice ?? '0',
                                    },
                                  );

                                  await controller.addToCart(
                                    productModel: productModel,
                                    price: Constant.productCommissionPrice(
                                      controller.vendorModel,
                                      matched.variantPrice ?? '0',
                                    ),
                                    discountPrice: '0',
                                    isIncrement: true,
                                    quantity: controller.quantity,
                                    variantInfo: [variantInfo],
                                  );

                                  Navigator.of(context).pop();
                                }
                              }
                            : null,
                        child: Text(
                          'Add to Cart'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
