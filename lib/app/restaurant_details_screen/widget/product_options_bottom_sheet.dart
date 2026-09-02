import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

void showProductOptionsBottomSheet({
  required BuildContext context,
  required RestaurantDetailsProvider controller,
  required ProductModel productModel,
  required String priceToPass,
  required String disPriceToPass,
  required double buttonFontSize,
}) {
  // ============================================================
  // NEW API
  // Product options = variants
  // Add-ons = optional legacy fields if your ProductModel keeps them
  // ============================================================

  final List<ProductVariant> options = productModel.variants ?? [];

  final bool hasOptions = options.isNotEmpty;

  final bool hasAddOns =
      productModel.addOnsTitle != null &&
      productModel.addOnsTitle!.isNotEmpty &&
      productModel.addOnsPrice != null &&
      productModel.addOnsPrice!.isNotEmpty;

  // Nothing to select.
  if (!hasOptions && !hasAddOns) {
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final Set<int> selectedOptionIndices = <int>{};

      final Set<int> selectedAddonIndices = <int>{};

      return StatefulBuilder(
        builder: (context, setState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppThemeData.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // HANDLE
                      // ==================================================
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppThemeData.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // ==================================================
                      // PRODUCT HEADER
                      // ==================================================
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productModel.productName ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemeData.grey900,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                if (hasOptions)
                                  Text(
                                    'Choose options'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppThemeData.grey600,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // CONTENT
                      // ==================================================
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ==================================================
                              // VARIANTS / OPTIONS
                              // ==================================================
                              if (hasOptions) ...[
                                Text(
                                  'Options'.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey800,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final ProductVariant option =
                                        options[index];

                                    final double optionPrice =
                                        double.tryParse(
                                          option.price?.toString() ?? '0',
                                        ) ??
                                        0;

                                    final String priceText =
                                        Constant.amountShow(
                                          amount:
                                              Constant.productCommissionPrice(
                                                controller.vendorModel,
                                                optionPrice.toString(),
                                              ),
                                        );

                                    final bool disabled =
                                        option.isAvailable == false ||
                                        option.price == null;

                                    final bool isSelected =
                                        selectedOptionIndices.contains(index);

                                    return InkWell(
                                      onTap: disabled
                                          ? null
                                          : () {
                                              setState(() {
                                                // Keep single
                                                // selection for
                                                // product variant.
                                                selectedOptionIndices.clear();

                                                selectedOptionIndices.add(
                                                  index,
                                                );
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppThemeData.primary300
                                                    .withOpacity(0.06)
                                              : AppThemeData.grey50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppThemeData.primary300
                                                : AppThemeData.grey200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Radio
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppThemeData.primary300
                                                      : AppThemeData.grey400,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? AppThemeData
                                                              .primary300
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // Variant name + price
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    option.variantName ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      color: disabled
                                                          ? AppThemeData.grey400
                                                          : AppThemeData
                                                                .grey900,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 2),

                                                  Text(
                                                    priceText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: disabled
                                                          ? AppThemeData.grey400
                                                          : AppThemeData
                                                                .grey700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 16),

                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppThemeData.grey200,
                                ),

                                const SizedBox(height: 16),
                              ],

                              // ==================================================
                              // ADD-ONS
                              // ==================================================
                              if (hasAddOns) ...[
                                Text(
                                  'Add-ons'.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey800,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: productModel.addOnsTitle!.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final title = productModel
                                        .addOnsTitle![index]
                                        .toString();

                                    final rawPrice =
                                        index < productModel.addOnsPrice!.length
                                        ? productModel.addOnsPrice![index]
                                              .toString()
                                        : '0';

                                    final priceText = Constant.amountShow(
                                      amount: Constant.productCommissionPrice(
                                        controller.vendorModel,
                                        rawPrice,
                                      ),
                                    );

                                    final bool isSelected = selectedAddonIndices
                                        .contains(index);

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedAddonIndices.remove(index);

                                            controller.selectedAddOns.remove(
                                              title,
                                            );
                                          } else {
                                            selectedAddonIndices.add(index);

                                            controller.selectedAddOns.add(
                                              title,
                                            );
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppThemeData.primary300
                                                    .withOpacity(0.06)
                                              : AppThemeData.grey50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppThemeData.primary300
                                                : AppThemeData.grey200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppThemeData.primary300
                                                      : AppThemeData.grey400,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? AppThemeData
                                                              .primary300
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      color:
                                                          AppThemeData.grey900,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 2),

                                                  Text(
                                                    priceText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppThemeData.grey700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // ADD BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeData.primary300,
                            foregroundColor: AppThemeData.grey50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            bool added = false;

                            if (hasOptions) {
                              for (final index in selectedOptionIndices) {
                                final selected = options[index];

                                if (selected.isAvailable == false) {
                                  continue;
                                }

                                final int? variantOptionId = int.tryParse(
                                  selected.variantId ?? '',
                                );
                                if (variantOptionId == null) {
                                  ShowToastDialog.showToast(
                                    'Invalid variant selected'.tr,
                                  );
                                  continue;
                                }

                                double selectedPrice =
                                    double.tryParse(
                                      selected.price?.toString() ?? '0',
                                    ) ??
                                    0;

                                if (selectedPrice <= 0) {
                                  selectedPrice =
                                      double.tryParse(priceToPass) ?? 0;
                                }

                                if (selectedPrice <= 0) {
                                  ShowToastDialog.showToast(
                                    'Invalid product price'.tr,
                                  );
                                  continue;
                                }

                                final String selectedPriceString = selectedPrice
                                    .toString();

                                final String optionPrice =
                                    Constant.productCommissionPrice(
                                      controller.vendorModel,
                                      selectedPriceString,
                                    );

                                final String variantName =
                                    selected.variantName ?? '';

                                final variantInfo = VariantInfo(
                                  variantId: variantOptionId.toString(),
                                  variantPrice: selectedPriceString,
                                  variantSku: variantName,
                                  variantOptions: {
                                    'option': variantName,
                                    'merchant_price':
                                        (selected.merchantPrice ??
                                                selected.price ??
                                                0)
                                            .toString(),
                                  },
                                );

                                controller.addToCart(
                                  productModel: productModel,
                                  price: optionPrice,
                                  discountPrice: '0',
                                  isIncrement: true,
                                  quantity: 1,
                                  variantInfo: variantInfo,
                                );
                                added = true;
                              }
                            }

                            // No variant selected (add-ons only / no options).
                            // variantOptionId is sent as null by addToCart.
                            if (!added) {
                              controller.addToCart(
                                productModel: productModel,
                                price: priceToPass,
                                discountPrice: disPriceToPass,
                                isIncrement: true,
                                quantity: 1,
                              );
                            }

                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Add'.tr,
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
