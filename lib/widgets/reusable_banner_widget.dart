import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/mart_banner_model.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_product_details_screen/mart_product_details_screen.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';

/// Reusable banner widget that works with both BannerModel and MartBannerModel
class ReusableBannerWidget extends StatefulWidget {
  final List<dynamic>
  banners; // Can be List<BannerModel> or List<MartBannerModel>
  final PageController pageController;
  final ValueNotifier<int> currentPage; // ✅ Change here
  final double height;
  final bool enableAutoScroll;
  final Duration autoScrollDuration;
  final Function()? onBannerTap;
  final Function()? onPanStart;
  final Function()? onPanEnd;
  final double? width;

  ReusableBannerWidget({
    super.key,
    required this.banners,
    required this.pageController,
    required this.currentPage,
    this.height = 150,
    this.enableAutoScroll = true,
    this.autoScrollDuration = const Duration(seconds: 3),
    this.onBannerTap,
    this.onPanStart,
    this.onPanEnd,
    this.width,
  });

  @override
  State<ReusableBannerWidget> createState() => _ReusableBannerWidgetState();
}

class _ReusableBannerWidgetState extends State<ReusableBannerWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    // For infinite scrolling, we need at least 2 banners
    if (widget.banners.length < 2) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: GestureDetector(
          onPanStart: (_) => widget.onPanStart?.call(),
          onPanEnd: (_) => widget.onPanEnd?.call(),
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: widget.pageController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.banners.length,
            padEnds: false,
            pageSnapping: true,
            onPageChanged: (value) {
              widget.currentPage.value = value;
            },
            itemBuilder: (BuildContext context, int index) {
              return _buildBannerItem(context, widget.banners[index]);
            },
          ),
        ),
      );
    }

    // Infinite scrolling implementation
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: GestureDetector(
        onPanStart: (_) => widget.onPanStart?.call(),
        onPanEnd: (_) => widget.onPanEnd?.call(),
        child: PageView.builder(
          physics: const BouncingScrollPhysics(),
          controller: widget.pageController,
          scrollDirection: Axis.horizontal,
          itemCount: widget.banners.length * 1000,
          // Create a large number for infinite effect
          padEnds: false,
          pageSnapping: true,
          onPageChanged: (value) {
            // Calculate the actual banner index
            int actualIndex = value % widget.banners.length;
            widget.currentPage.value = actualIndex;
          },
          itemBuilder: (BuildContext context, int index) {
            // Calculate the actual banner index
            int actualIndex = index % widget.banners.length;
            return _buildBannerItem(context, widget.banners[actualIndex]);
          },
        ),
      ),
    );
  }

  Widget _buildBannerItem(BuildContext context, dynamic banner) {
    String? imageUrl;
    String? title;
    String? text;
    String? description;
    String? redirectType;
    String? redirectId;
    // Handle both BannerModel and MartBannerModel
    if (banner is BannerModel) {
      imageUrl = banner.photo;
      title = banner.title;
      redirectType = banner.redirectType;
      redirectId = banner.redirectId;
    } else if (banner is MartBannerModel) {
      imageUrl = banner.photo;
      title = banner.title;
      text = banner.text;
      description = banner.description;
      redirectType = banner.redirectType;
      redirectId = banner.redirectId;
    }

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return InkWell(
          onTap: () => _handleBannerTap(context, redirectType, redirectId),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        // Lazy loading - show placeholder immediately while image loads in background
                        return Container(color: Colors.grey[50], child: child);
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),

                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Banner text content
                  if (title != null || text != null || description != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title removed - only show text and description
                            if (text != null && text.isNotEmpty)
                              Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (description != null && description.isNotEmpty)
                              const SizedBox(height: 4),
                            if (description != null && description.isNotEmpty)
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBannerTap(
    BuildContext context,
    String? redirectType,
    String? redirectId,
  ) async {
    print(
      '[BANNER NAVIGATION] 🎯 Banner tapped - Type: $redirectType, ID: $redirectId',
    );
    print("_handleBannerTap ${redirectType}  ${redirectId}");
    if (redirectType == null || redirectId == null) {
      print('[BANNER NAVIGATION] ❌ Missing redirect type or ID');
      return;
    }
    try {
      switch (redirectType) {
        case 'store':
          print('[BANNER NAVIGATION] 🏪 Store redirect');
          await _handleStoreRedirect(redirectId, context);
          break;
        case 'product':
          print('[BANNER NAVIGATION] 🛍️ Product redirect');
          await _handleProductRedirect(redirectId, context);
          break;
        case 'category':
        case 'mart_category':
          print('[BANNER NAVIGATION] 📂 Category redirect');
          await _handleCategoryRedirect(redirectId, context);
          break;
        case 'external_link':
          print('[BANNER NAVIGATION] 🔗 External link redirect');
          await _handleExternalLinkRedirect(redirectId);
          break;
        default:
          print('[BANNER NAVIGATION] ❓ Unknown redirect type: $redirectType');
      }
    } catch (e) {
      print('[BANNER NAVIGATION] ❌ Error handling banner tap: $e');
      ShowToastDialog.showToast('Unable to open link. Please try again.');
    }
  }

  Future<void> _handleStoreRedirect(
    String storeId,
    BuildContext context,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);

    try {
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(storeId);

      if (vendorModel != null) {
        if (vendorModel.zoneId == Constant.selectedZone?.id) {
          ShowToastDialog.closeLoader();
          RestaurantDetailsProvider restaurantDetailsProvider =
              Provider.of<RestaurantDetailsProvider>(context, listen: false);
          restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
          Get.to(
            const RestaurantDetailsScreen(),
            arguments: {"vendorModel": vendorModel},
          );
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Sorry, The Zone is not available in your area. Change the other location first."
                .tr,
          );
        }
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Store not found".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error loading store details".tr);
    }
  }

  Future<void> _handleProductRedirect(
    String productId,
    BuildContext context,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);

    try {
      // Try to get mart item first
      final martService = Get.find<MartFirestoreService>();
      MartItemModel? martItem = await martService.getItemById(productId);

      if (martItem != null) {
        // This is a mart product
        ShowToastDialog.closeLoader();
        Get.to(MartProductDetailsScreen(product: martItem));
      } else {
        ProductModel? productModel = await FireStoreUtils.getProductById(
          productId,
        );
        if (productModel != null) {
          VendorModel? vendorModel = await FireStoreUtils.getVendorById(
            productModel.vendorID.toString(),
          );
          if (vendorModel != null) {
            if (vendorModel.zoneId == Constant.selectedZone?.id) {
              ShowToastDialog.closeLoader();
              RestaurantDetailsProvider restaurantDetailsProvider =
                  Provider.of<RestaurantDetailsProvider>(
                    context,
                    listen: false,
                  );
              restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
              Get.to(
                const RestaurantDetailsScreen(),
                arguments: {"vendorModel": vendorModel},
              );
            } else {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showToast(
                "Sorry, The Zone is not available in your area. Change the other location first."
                    .tr,
              );
            }
          } else {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast("Store not found".tr);
          }
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Product not found".tr);
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error loading product details".tr);
    }
  }

  late CategoryDetailsProvider categoryDetailsProvider;

  Future<void> _handleCategoryRedirect(
    String categoryId,
    BuildContext context,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    categoryDetailsProvider = Provider.of<CategoryDetailsProvider>(
      context,
      listen: false,
    );
    try {
      ShowToastDialog.closeLoader();
      categoryDetailsProvider.initFunction(
        categoryIds: categoryId,
        categoryNames: 'Category',
      );
      Get.to(() => const MartCategoryDetailScreen());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error loading category details".tr);
    }
  }

  Future<void> _handleExternalLinkRedirect(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ShowToastDialog.showToast('Unable to open link');
      }
    } catch (e) {
      ShowToastDialog.showToast('Unable to open link');
    }
  }
}
