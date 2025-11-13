import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/widget/grocery_component_widget.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/widget/mart_header_card.dart';
import 'package:jippymart_customer/app/mart/mart_search_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/app/mart/widgets/mart_product_home_card.dart';
import 'package:jippymart_customer/app/mart/widgets/playtime_product_card.dart';
import 'package:jippymart_customer/models/mart_banner_model.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/themes/mart_theme.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/widget/animated_search_hint.dart';
import 'package:jippymart_customer/widgets/reusable_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MartHomeScreen extends StatelessWidget {
  const MartHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    Size size = MediaQuery.of(context).size;
    return Theme(
      data: MartTheme.theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Consumer<MartProvider>(
          builder: (context, controller, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.featuredCategories.isEmpty &&
                  !controller.isCategoryLoading &&
                  !controller.isHomepageCategoriesLoaded) {
                controller.loadHomepageCategoriesStreaming(limit: 6);
              }
              if (controller.featuredItems.isEmpty &&
                  !controller.isProductLoading) {
                controller.loadFeaturedItemsStreaming();
              }
              if (controller.trendingItems.isEmpty &&
                  !controller.isTrendingLoading) {
                controller.loadTrendingItemsStreaming();
              }
              // Load subcategories for the subcategories section
              if (controller.subcategories.isEmpty &&
                  !controller.isSubcategoryLoading) {
                if (controller.featuredCategories.isNotEmpty) {
                  final mainCategory = controller.featuredCategories[0];
                  controller.loadSubcategoriesStreaming(mainCategory.id ?? '');
                }
              }
              Future.microtask(() {
                controller.loadMartBannersStream();
              });
              if (controller.martTopBanners.isNotEmpty) {
                controller.startMartBannerTimer();
              }
            });
            return SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 430,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ColorConst.greenLight,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(26),
                            bottomRight: Radius.circular(26),
                          ), // set your desired radius
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: controller.refreshData,
                        child: Column(
                          children: [
                            MartHeaderCard(screenWidth: screenWidth),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Get.to(() => const MartSearchScreen());
                                },
                                child: AnimatedSearchHint(
                                  controller: null,
                                  enable: false,
                                  fillColor: Colors.white,
                                  fontFamily: 'Outfit-Bold',
                                  textStyle: TextStyle(
                                    fontFamily: 'Outfit-Bold',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                  hintTextStyle: TextStyle(
                                    fontFamily: 'Outfit-Bold',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                  suffix: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: SvgPicture.asset(
                                      "assets/icons/ic_search.svg",
                                      color: Color(0xFFff5201),
                                    ),
                                  ),
                                  hints: [
                                    "Search 'milk'",
                                    "Search 'bread'",
                                    "Search 'rice'",
                                    "Search 'atta'",
                                    "Search 'oil'",
                                    "Search 'sugar'",
                                    "Search 'tea'",
                                    "Search 'coffee'",
                                    "Search 'snacks'",
                                    "Search 'biscuits'",
                                    "Search 'cold drinks'",
                                    "Search 'toothpaste'",
                                    "Search 'detergent'",
                                    "Search 'shampoo'",
                                    "Search 'soap'",
                                    "Search 'cleaning supplies'",
                                    "Search 'baby care'",
                                    "Search 'personal care'",
                                    "Search 'frozen food'",
                                    "Search 'fresh vegetables'",
                                    "Search 'fruits'",
                                    "Search 'eggs'",
                                    "Search 'dry fruits'",
                                    "Search 'masala'",
                                    "Search 'instant food'",
                                    "Search 'breakfast items'",
                                    "Search 'stationery'",
                                    "Search 'pet food'",
                                    "Search 'household essentials'",
                                    "Search 'kitchen items'",
                                    "Search 'offers near you'",
                                    "Search 'best deals'",
                                    "Search 'today’s discount'",
                                    "Search 'new arrivals'",
                                    "Search 'bestsellers'",
                                  ],
                                  interval: const Duration(seconds: 2),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            controller.martTopBanners.isNotEmpty
                                ? Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10.0,
                                          right: 10,
                                          top: 10,
                                        ),
                                        child: ReusableBannerWidget(
                                          banners: controller.martTopBanners,
                                          pageController: controller
                                              .martTopBannerController,
                                          currentPage:
                                              controller.currentTopBannerPage,
                                          height: 150,
                                          onPanStart: () =>
                                              controller.stopMartBannerTimer(),
                                          onPanEnd: () =>
                                              controller.startMartBannerTimer(),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                            SizedBox(height: 10),
                            groceryComponent(size),
                            MartDynamicSectionsEnhanced(
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: GestureDetector(
          onTap: () async {
            // WhatsApp number - you can change this to your desired number
            const String phoneNumber =
                '+919390579864'; // Your actual WhatsApp number
            const String message =
                'Hello! I need help with my JippyMart order.'; // Customize the message

            final Uri whatsappUrl = Uri.parse(
              'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
            );

            try {
              if (await canLaunchUrl(whatsappUrl)) {
                await launchUrl(
                  whatsappUrl,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                // Fallback to regular phone call if WhatsApp is not available
                final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
                if (await canLaunchUrl(phoneUrl)) {
                  await launchUrl(
                    phoneUrl,
                    mode: LaunchMode.externalApplication,
                  );
                }
              }
            } catch (e) {
              print('Error launching WhatsApp: $e');
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.green, // WhatsApp green color
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: SvgPicture.asset(
                'assets/images/whatsapp.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MartSpotlightSelections extends StatelessWidget {
  final double screenWidth;

  const MartSpotlightSelections({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 413,
      height: 263,
      decoration: const BoxDecoration(
        color: Color(0xFF00998a), // Rectangle 5 background
      ),
      child: Stack(
        children: [
          // Face In Clouds icon
          Positioned(
            left: 169,
            top: 19,
            child: SizedBox(
              width: 67,
              height: 67,
              child: Image.asset(
                'assets/images/FaceInClouds.gif',
                width: 67,
                height: 67,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 67,
                    height: 67,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(33.5),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),

          // Spotlight Selections title
          Positioned(
            left: 35,
            top: 86,
            child: const Text(
              'Spotlight Selections',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 39 / 32,
                color: Colors.white,
              ),
            ),
          ),

          // Frame 40 - Horizontal scrollable container
          Positioned(
            left: 1,
            top: 150,
            child: SizedBox(
              width: 402,
              height: 92,
              child: Consumer<MartProvider>(
                builder: (context, controller, _) {
                  if (controller.spotlightItems.isEmpty) {
                    return const Center(
                      child: Text(
                        'No spotlight items available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...controller.spotlightItems.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final item = entry.value;

                          return Row(
                            children: [
                              _SpotlightCard(
                                title: item['title'] ?? 'Category',
                                discount: item['discount'] ?? 'Up to 50% OFF',
                              ),
                              // Add spacing between cards (except for the last one)
                              if (index < controller.spotlightItems.length - 1)
                                const SizedBox(width: 12),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Spotlight Card widget matching CSS specifications
class _SpotlightCard extends StatelessWidget {
  final String title;
  final String discount;

  const _SpotlightCard({required this.title, required this.discount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show coming soon message
        Get.snackbar(
          'Coming Soon',
          'This feature is under development',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: SizedBox(
        width: 88,
        height: 92,
        child: Stack(
          children: [
            // Rectangle background (white card)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 88,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9EE),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            // Category title - positioned based on CSS
            Positioned(
              left: 4,
              top: 7,
              child: SizedBox(
                width: 80,
                height: 24,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 12 / 10,
                    color: Color(0xFF000000),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Gradient offer bar - positioned based on CSS
            Positioned(
              left: 4,
              top: 73,
              child: Container(
                width: 80,
                height: 15,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF595BD4), // #595BD4
                      Color(0xFF9140D8), // #9140D8
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
              ),
            ),

            // Discount text - positioned based on CSS
            Positioned(
              left: 12,
              top: 76,
              child: Text(
                discount,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  height: 9 / 7,
                  color: Colors.white,
                ),
              ),
            ),

            // Placeholder icon in center (Rectangle with background url)
            Positioned(
              left: 30, // Fixed position for all cards
              top: 36, // 39.13% of 92px ≈ 36px
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D56F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper method for spotlight subcategories

class _GroceryItem extends StatelessWidget {
  final String label;
  final String? imageUrl;

  const _GroceryItem({required this.label, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Coming Soon',
          'This feature is under development',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: SizedBox(
        width: 87,
        height: 129,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 87,
                height: 91,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAFD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          width: 87,
                          height: 91,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEAFD),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Color(0xFF5D56F3),
                                size: 30,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEAFD),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF5D56F3),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEAFD),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF5D56F3),
                            size: 30,
                          ),
                        ),
                ),
              ),
            ),

            // Text label
            Positioned(
              left: 9, // 24 - 15 (container left offset)
              top: 99, // 817 - 718 (top offset)
              child: SizedBox(
                width: 70,
                height: 30,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 15 / 12,
                    // line-height: 15px
                    color: Color(0xFF000000),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MartGlowWellnessSection extends StatelessWidget {
  final double screenWidth;

  const MartGlowWellnessSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'GLOW & WELLNESS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 16),
          // Wellness Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 87 / 129,
            // Exact ratio from CSS
            children: [
              _GroceryItem(
                label: 'Bath &\nBody',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Hair\nCare',
                imageUrl:
                    'https://images.unsplash.com/photo-1522338140263-f46f5913618a?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Skincare',
                imageUrl:
                    'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Makeup',
                imageUrl:
                    'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Oral\nCare',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Grooming',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Baby\nCare',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Fragrances',
                imageUrl:
                    'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Protein and\nSupplements',
                imageUrl:
                    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Feminine\nHygiene',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Sexual\nWellness',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Health and\nPharma',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MartSnacksRefreshmentsSection extends StatelessWidget {
  final double screenWidth;

  const MartSnacksRefreshmentsSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'SNACKS & REFRESHMENTS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 16),

          // Snacks Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 87 / 129,
            // Exact ratio from CSS
            children: [
              _GroceryItem(
                label: 'Cold Drinks\nand Juices',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Ice Creams and\nFrozen Desserts',
                imageUrl:
                    'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Chips and\nNamkeens',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Chocolates',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Noodles Pasta\nVermicelli',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Frozen\nFood',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Sweets',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Paan\nCorner',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MartEverydayLifeHomeSection extends StatelessWidget {
  final double screenWidth;

  const MartEverydayLifeHomeSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'EVERYDAY LIFE & HOME',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 16),

          // Everyday Life Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 87 / 129,
            // Exact ratio from CSS
            children: [
              _GroceryItem(
                label: 'Home and\nFurnishing',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Kitchen and\nDining',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Cleaning\nEssentials',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Clothing',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Mobiles and\nElectronics',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Appliances',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Books and\nStationery',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Jewellery and\nAccessories',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Puja',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Toys and\nGames',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Sports and\nFitness',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
              _GroceryItem(
                label: 'Pet\nSupplies',
                imageUrl:
                    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MartLocalStoreSection extends StatelessWidget {
  final double screenWidth;

  const MartLocalStoreSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'LOCAL STORE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 16),

          // Local Store Categories - Horizontal Scroll
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                _LocalStoreItem(
                  label: 'Party Store',
                  color: const Color(0xFFD8D5FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Gourmet Store',
                  color: const Color(0xFFFFE4B5),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Puja Store',
                  color: const Color(0xFFFFE4E1),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Local Favourites',
                  color: const Color(0xFFFFE4B5),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Toys & Stationery',
                  color: const Color(0xFFFFE4E1),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Gifting Store',
                  color: const Color(0xFFE0E0FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Pet Store',
                  color: const Color(0xFFE8D7C6),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Health & Fitness',
                  color: const Color(0xFFD8D5FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Travel Store',
                  color: const Color(0xFFE0E0FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Electronics Store',
                  color: const Color(0xFFD8D5FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Fashion Store',
                  color: const Color(0xFFFFE4E1),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Beauty Store',
                  color: const Color(0xFFFFE4B5),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Sports Store',
                  color: const Color(0xFFE8D7C6),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Book Store',
                  color: const Color(0xFFD8D5FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Music Store',
                  color: const Color(0xFFE0E0FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Art & Craft',
                  color: const Color(0xFFFFE4B5),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Garden Store',
                  color: const Color(0xFFE8D7C6),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Auto Store',
                  color: const Color(0xFFD8D5FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Hardware Store',
                  color: const Color(0xFFE0E0FF),
                  screenWidth: screenWidth,
                ),
                _LocalStoreItem(
                  label: 'Pharmacy',
                  color: const Color(0xFFFFE4E1),
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalStoreItem extends StatelessWidget {
  final String label;
  final Color color;
  final double screenWidth;

  const _LocalStoreItem({
    required this.label,
    required this.color,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final itemSize = 120.0; // Further reduced size to fit

    return Container(
      width: itemSize + 12, // Add margin
      margin: const EdgeInsets.only(right: 2),
      child: Column(
        children: [
          Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D1B69),
            ),
          ),
        ],
      ),
    );
  }
}

class MartTrendingTodaySection extends StatelessWidget {
  final double screenWidth;

  const MartTrendingTodaySection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Trending Today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Scroll of Promotional Cards
          SizedBox(
            height: 203,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: List.generate(10, (index) => _TrendingCard()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MartProvider>(
      builder: (context, controller, _) {
        return StreamBuilder<List<MartBannerModel>>(
          stream: controller.streamBannersByPosition('top', limit: 1),
          builder: (context, snapshot) {
            // Default data if no banner is available
            String title = 'Nurture with love';
            String description =
                'Find a range of trusted essentials for mom & baby';
            String buttonText = 'SHOP NOW';

            // Use real data if available
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final banner = snapshot.data!.first;
              title = (banner.title?.isNotEmpty == true)
                  ? banner.title!
                  : title;
              description =
                  (banner.description?.isNotEmpty == true &&
                      banner.description != '-')
                  ? banner.description!
                  : description;
              buttonText = 'SHOP NOW'; // Keep button text consistent
            }

            return GestureDetector(
              onTap: () {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  try {
                    controller.handleBannerTap(snapshot.data!.first);
                  } catch (e) {
                    print(
                      '[MART HOME] Controller not found for banner tap: $e',
                    );
                  }
                }
              },
              child: Container(
                width: 300,
                height: 203,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5C5C99), Color(0xFF1F1F33)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Title
                    Positioned(
                      left: 20,
                      top: 16,
                      child: SizedBox(
                        width: 158,
                        height: 78,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.22,
                            // 39/32
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Subtitle
                    Positioned(
                      left: 20,
                      top: 102,
                      child: SizedBox(
                        width: 174,
                        height: 32,
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.23,
                            // 16/13
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Shop Now Button
                    Positioned(
                      left: 20,
                      top: 151,
                      child: Container(
                        width: 130,
                        height: 39,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9EE),
                          borderRadius: BorderRadius.circular(70),
                        ),
                        child: Center(
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.21,
                              // 17/14
                              color: Color(0xFF00998a),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class MartProductDealsSection extends StatelessWidget {
  final double screenWidth;

  const MartProductDealsSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        // left: 16,
        // right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with See All
          // Container(
          //   width: double.infinity,
          //   height: 22,
          //   child: Stack(
          //     children: [
          //       // Section title
          //       const Positioned(
          //         left: 9, // 25 - 16 (container padding)
          //         top: 0,
          //         child: Text(
          //           'Trending deals',
          //           style: TextStyle(
          //             fontFamily: 'Montserrat',
          //             fontSize: 18,
          //             fontWeight: FontWeight.w600,
          //             height: 22 / 18, // line-height: 22px
          //             color: Color(0xFF000000),
          //           ),
          //         ),
          //       ),
          //
          //       // See All text
          //       Positioned(
          //         right: 32, // 338 - 280 (container width - text position)
          //         top: 3, // 3123 - 3120 (top offset)
          //         child: GestureDetector(
          //           onTap: () {
          //             // Navigate to category detail screen with trending filter
          //             Get.to(() => MartCategoryDetailScreen(), arguments: {
          //               'categoryId': 'trending',
          //               'categoryName': 'Trending Deals',
          //               'initialFilter': 'trending',
          //             });
          //           },
          //           child: const Text(
          //             'See All',
          //             style: TextStyle(
          //               fontFamily: 'Montserrat',
          //               fontSize: 14,
          //               fontWeight: FontWeight.w600,
          //               height: 17 / 14, // line-height: 17px
          //               color: Color(0xFF1717FE),
          //             ),
          //           ),
          //         ),
          //       ),
          //
          //
          //       // Right arrow icon
          //       Positioned(
          //         right: 9, // 387 - 378 (container width - icon position)
          //         top: 0,
          //         child: Container(
          //           width: 24,
          //           height: 24,
          //           child: const Icon(
          //             Icons.arrow_forward_ios,
          //             size: 16,
          //             color: Color(0xFF1717FE),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trending deals',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to category detail screen with trending filter
                    Get.to(
                      () => MartCategoryDetailScreen(),
                      arguments: {
                        'categoryId': 'trending',
                        'categoryName': 'Trending Deals',
                        'initialFilter': 'trending',
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConst.martPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorConst.martPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<MartProvider>(
            builder: (context, controller, _) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  // right: 16,
                ),
                child: SizedBox(
                  height: 215,
                  child: StreamBuilder<List<MartItemModel>>(
                    stream: controller.streamProductDeals(limit: 10),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading products'),
                        );
                      }

                      final products = snapshot.data ?? [];

                      if (products.isEmpty) {
                        return const Center(
                          child: Text('No products available'),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return _martItemToPlaytimeCard(
                            products[index],
                            screenWidth,
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class MartHairCareSection extends StatelessWidget {
  final double screenWidth;

  const MartHairCareSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with See All
          SizedBox(
            width: double.infinity,
            height: 22,
            child: Stack(
              children: [
                // Section title
                const Positioned(
                  left: 9,
                  top: 0,
                  child: Text(
                    'Deals on Hair Care',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 22 / 18,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),

                // See All text
                Positioned(
                  right: 32,
                  top: 3,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 17 / 14,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),

                // Right arrow icon
                Positioned(
                  right: 9,
                  top: 0,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Cards - Horizontal Scroll
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: List.generate(
                10,
                (index) => PlaytimeProductCard(
                  volume: '580 ml',
                  productName: 'Keratin Smooth Shampoo',
                  discount: '40% OFF',
                  currentPrice: '₹619',
                  originalPrice: '₹1016',
                  screenWidth: screenWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MartChocolatesSection extends StatelessWidget {
  final double screenWidth;

  const MartChocolatesSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with See All
          SizedBox(
            width: double.infinity,
            height: 22,
            child: Stack(
              children: [
                // Section title
                const Positioned(
                  left: 9,
                  top: 0,
                  child: Text(
                    'Best deals on Chocolates',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 22 / 18,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),

                // See All text
                Positioned(
                  right: 32,
                  top: 3,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 17 / 14,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),

                // Right arrow icon
                Positioned(
                  right: 9,
                  top: 0,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Cards - Horizontal Scroll
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: List.generate(
                10,
                (index) => PlaytimeProductCard(
                  volume: '150 g',
                  productName: 'Amul Dark Chocolate',
                  discount: '8% OFF',
                  currentPrice: '₹179',
                  originalPrice: '₹200',
                  screenWidth: screenWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MartPlaytimeSection extends StatelessWidget {
  final double screenWidth;

  const MartPlaytimeSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with See All
          SizedBox(
            width: double.infinity,
            height: 22,
            child: Stack(
              children: [
                // Section title
                const Positioned(
                  left: 9,
                  top: 0,
                  child: Text(
                    'Playtime Savings',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 22 / 18,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),

                // See All text
                Positioned(
                  right: 32,
                  top: 3,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 17 / 14,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),

                // Right arrow icon
                Positioned(
                  right: 9,
                  top: 0,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Cards - Horizontal Scroll
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Teddy bear',
                  discount: '25% OFF',
                  currentPrice: '₹399',
                  originalPrice: '₹500',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Fluffy Bear',
                  discount: '45% OFF',
                  currentPrice: '₹699',
                  originalPrice: '₹1000',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'UNO',
                  discount: '30% OFF',
                  currentPrice: '₹199',
                  originalPrice: '₹300',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Teddy bear',
                  discount: '25% OFF',
                  currentPrice: '₹399',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Teddy bear',
                  discount: '25% OFF',
                  currentPrice: '₹399',
                  originalPrice: '₹500',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Fluffy Bear',
                  discount: '45% OFF',
                  currentPrice: '₹699',
                  originalPrice: '₹1000',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'UNO',
                  discount: '30% OFF',
                  currentPrice: '₹199',
                  originalPrice: '₹300',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Teddy bear',
                  discount: '25% OFF',
                  currentPrice: '₹399',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Teddy bear',
                  discount: '25% OFF',
                  currentPrice: '₹399',
                  originalPrice: '₹500',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Fluffy Bear',
                  discount: '45% OFF',
                  currentPrice: '₹699',
                  originalPrice: '₹1000',
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MartBabyCareSection extends StatelessWidget {
  final double screenWidth;

  const MartBabyCareSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with See All
          SizedBox(
            width: double.infinity,
            height: 22,
            child: Stack(
              children: [
                // Section title
                const Positioned(
                  left: 9,
                  top: 0,
                  child: Text(
                    'Best deals on Baby Care',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 22 / 18,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),

                // See All text
                Positioned(
                  right: 32,
                  top: 3,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 17 / 14,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),

                // Right arrow icon
                Positioned(
                  right: 9,
                  top: 0,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Cards - Horizontal Scroll
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Huggies Larg 32 pieces',
                  discount: '32% OFF',
                  currentPrice: '₹359',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Pampers XL 78 pieces',
                  discount: '20% OFF',
                  currentPrice: '₹1579',
                  originalPrice: '₹1049',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Huggies Larg 32 pieces',
                  discount: '32% OFF',
                  currentPrice: '₹359',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Pampers XL 78 pieces',
                  discount: '20% OFF',
                  currentPrice: '₹1579',
                  originalPrice: '₹1049',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Huggies Larg 32 pieces',
                  discount: '32% OFF',
                  currentPrice: '₹359',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Pampers XL 78 pieces',
                  discount: '20% OFF',
                  currentPrice: '₹1579',
                  originalPrice: '₹1049',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Huggies Larg 32 pieces',
                  discount: '32% OFF',
                  currentPrice: '₹359',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Pampers XL 78 pieces',
                  discount: '20% OFF',
                  currentPrice: '₹1579',
                  originalPrice: '₹1049',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Huggies Larg 32 pieces',
                  discount: '32% OFF',
                  currentPrice: '₹359',
                  originalPrice: '₹450',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '',
                  productName: 'Pampers XL 78 pieces',
                  discount: '20% OFF',
                  currentPrice: '₹1579',
                  originalPrice: '₹1049',
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MartLocalGrocerySection extends StatelessWidget {
  final double screenWidth;

  const MartLocalGrocerySection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with See All
          SizedBox(
            width: double.infinity,
            height: 22,
            child: Stack(
              children: [
                // Section title
                const Positioned(
                  left: 9,
                  top: 0,
                  child: Text(
                    'Local Grocery Essentials',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 22 / 18,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),

                // See All text
                Positioned(
                  right: 32,
                  top: 3,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 17 / 14,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),

                // Right arrow icon
                Positioned(
                  right: 9,
                  top: 0,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1717FE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Cards - Horizontal Scroll
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Aashirvaad Atta',
                  discount: '15% OFF',
                  currentPrice: '₹549',
                  originalPrice: '₹640',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Sona Masoori Economy Rice',
                  discount: '40% OFF',
                  currentPrice: '₹1189',
                  originalPrice: '₹2200',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '5 ltr',
                  productName: 'Gold Drop Refined Sunflower Oil',
                  discount: '20% OFF',
                  currentPrice: '₹739',
                  originalPrice: '₹950',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Aashirvaad Atta',
                  discount: '15% OFF',
                  currentPrice: '₹549',
                  originalPrice: '₹640',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Sona Masoori Economy Rice',
                  discount: '40% OFF',
                  currentPrice: '₹1189',
                  originalPrice: '₹2200',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '5 ltr',
                  productName: 'Gold Drop Refined Sunflower Oil',
                  discount: '20% OFF',
                  currentPrice: '₹739',
                  originalPrice: '₹950',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Aashirvaad Atta',
                  discount: '15% OFF',
                  currentPrice: '₹549',
                  originalPrice: '₹640',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Sona Masoori Economy Rice',
                  discount: '40% OFF',
                  currentPrice: '₹1189',
                  originalPrice: '₹2200',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '5 ltr',
                  productName: 'Gold Drop Refined Sunflower Oil',
                  discount: '20% OFF',
                  currentPrice: '₹739',
                  originalPrice: '₹950',
                  screenWidth: screenWidth,
                ),
                PlaytimeProductCard(
                  volume: '10 kg',
                  productName: 'Aashirvaad Atta',
                  discount: '15% OFF',
                  currentPrice: '₹549',
                  originalPrice: '₹640',
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MartSloganSection extends StatelessWidget {
  final double screenWidth;

  const MartSloganSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 353,
      color: const Color(0xFFEEEEF2),
      child: Stack(
        children: [
          // "Basket full" text
          Positioned(
            left: 26, // 27 - 1 (container left offset)
            top: 54, // 5169 - 5115 (top offset)
            child: const Text(
              'Basket full',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 49 / 40,
                // line-height: 49px
                color: Color(0xFF787878),
              ),
            ),
          ),

          // "Heart full !" text
          Positioned(
            left: 27, // 28 - 1 (container left offset)
            top: 103, // 5218 - 5115 (top offset)
            child: const Text(
              'Heart full !',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 50,
                fontWeight: FontWeight.w800,
                height: 61 / 50,
                // line-height: 61px
                color: Color(0xFF787878),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MartFeaturedProducts extends StatelessWidget {
  final double screenWidth;

  const MartFeaturedProducts({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(
        //     left: 16,
        //     right: 16,
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       const Text(
        //         'Featured Products',
        //         style: TextStyle(
        //           fontSize: 20,
        //           fontWeight: FontWeight.bold,
        //           color: Color(0xFF2D1B69),
        //         ),
        //       ),
        //       GestureDetector(
        //         onTap: () {
        //           // Navigate to category detail screen with featured filter
        //           Get.to(() => MartCategoryDetailScreen(), arguments: {
        //             'categoryId': 'featured',
        //             'categoryName': 'Featured Products',
        //             'initialFilter': 'featured',
        //           });
        //         },
        //         child: const Text(
        //           'See All >',
        //           style: TextStyle(
        //             fontSize: 16,
        //             color: Colors.blue,
        //             fontWeight: FontWeight.w600,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Products',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => MartCategoryDetailScreen(),
                    arguments: {
                      'categoryId': 'featured',
                      'categoryName': 'Featured Products',
                      'initialFilter': 'featured',
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorConst.martPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorConst.martPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Consumer<MartProvider>(
          builder: (context, controller, _) {
            if (controller.isProductLoading) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.featuredItems.isEmpty) {
              return SizedBox(
                height: 280,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 64, color: Colors.grey),
                      const SizedBox(height: 8), // Reduced from 16 to 8
                      const Text(
                        'No featured products found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isTablet = screenWidth > 600;
                final isLargePhone = screenWidth > 400;
                // Calculate dynamic card width based on screen size
                final cardWidth = isTablet
                    ? 200.0
                    : (isLargePhone ? 130.0 : 130.0);
                // 🔑 Auto-adjustable layout using Wrap for truly flexible card heights
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    // right: 16,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      runAlignment: WrapAlignment.start,
                      spacing: 0,
                      runSpacing: 0,
                      children: controller.featuredItems.map((product) {
                        return SizedBox(
                          width: cardWidth,
                          child: MartProductCardHome(
                            product: product,
                            screenWidth: screenWidth,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// Helper function to parse color from hex string
Color _parseColor(String hexColor) {
  try {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Add alpha channel
    }
    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return const Color(0xFFE8E4FF); // Default color
  }
}

// Helper function to sanitize image URLs
// Enhanced version that uses controller methods
class MartDynamicSectionsEnhanced extends StatefulWidget {
  final double screenWidth;

  const MartDynamicSectionsEnhanced({super.key, required this.screenWidth});

  @override
  State<MartDynamicSectionsEnhanced> createState() =>
      _MartDynamicSectionsEnhancedState();
}

class _MartDynamicSectionsEnhancedState
    extends State<MartDynamicSectionsEnhanced> {
  bool _hasTriggeredLoading = false;

  // @override
  //   void initState() {
  //   final controller = Get.put(MartController());
  //   controller.  loadCategoryProductsForSections();
  //     super.initState();
  //   }
  @override
  Widget build(BuildContext context) {
    return Consumer<MartProvider>(
      builder: (context, controller, _) {
        // Trigger category products loading
        if (!_hasTriggeredLoading) {
          _hasTriggeredLoading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.loadCategoryProductsForSections();
          });
        }

        final categoryProducts = controller.categoryProductsMap;
        final uniqueCategories = controller.uniqueCategoryTitles;

        if (uniqueCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: uniqueCategories.map((category) {
            return _buildCategorySection(
              controller,
              category,
              categoryProducts[category] ?? [],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategorySection(
    MartProvider controller,
    String categoryName,
    List<MartItemModel> products,
  ) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    print(
                      '[MART DYNAMIC SECTIONS] 🔗 Navigating to category: $categoryName',
                    );

                    // Find the category ID for this category title
                    final category = controller.martCategories.firstWhere(
                      (cat) => cat.title == categoryName,
                      orElse: () =>
                          MartCategoryModel(id: '', title: categoryName),
                    );

                    Get.to(
                      () => MartCategoryDetailScreen(),
                      arguments: {
                        'categoryId':
                            category.id ??
                            'category_${categoryName.toLowerCase().replaceAll(' ', '_')}',
                        'categoryName': categoryName,
                        'initialFilter': 'category',
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConst.martPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorConst.martPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              height: 215,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return PlaytimeProductCard(
                    volume: '${product.grams ?? 0}${_getVolumeUnit(product)}',
                    productName: product.name,
                    discount: '${_calculateDiscount(product)}% OFF',
                    currentPrice: '₹${product.disPrice ?? product.price}',
                    originalPrice: '₹${product.price}',
                    screenWidth: widget.screenWidth,
                    imageUrl: product.photo,
                    product: product,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24), // Add spacing between sections
        ],
      ),
    );
  }

  String _getVolumeUnit(MartItemModel product) {
    if (product.grams != null && product.grams! > 0) {
      return 'g';
    }
    return 'g'; // Default to grams
  }

  int _calculateDiscount(MartItemModel product) {
    if (product.disPrice != null && product.price > product.disPrice!) {
      return ((product.price - product.disPrice!) / product.price * 100)
          .round();
    }
    return 0;
  }
}

// Dynamic Sections Widget
class MartDynamicSections extends StatefulWidget {
  final double screenWidth;

  const MartDynamicSections({super.key, required this.screenWidth});

  @override
  State<MartDynamicSections> createState() => _MartDynamicSectionsState();
}

class _MartDynamicSectionsState extends State<MartDynamicSections> {
  bool _hasTriggeredLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<MartProvider>(
      builder: (context, controller, _) {
        // Trigger sections loading only once to prevent blinking
        if (!_hasTriggeredLoading && controller.availableSections.isEmpty) {
          _hasTriggeredLoading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.loadSectionsImmediately();
            Future.delayed(const Duration(seconds: 2), () {
              if (controller.availableSections.isEmpty) {
                controller.addTestSections();
              }
            });
          });
        }
        if (controller.availableSections.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: controller.availableSections.map((section) {
            return _buildSection(controller, section);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSection(MartProvider controller, String sectionName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        // left: 16,
        // right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sectionName,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print(
                      '[MART DYNAMIC SECTIONS] 🔗 Navigating to section: $sectionName',
                    );
                    Get.to(
                      () => MartCategoryDetailScreen(),
                      arguments: {
                        'categoryId':
                            'section_${sectionName.toLowerCase().replaceAll(' ', '_')}',
                        'categoryName': sectionName,
                        'initialFilter': 'section',
                        'sectionName': sectionName,
                        // Pass the actual section name
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConst.martPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorConst.martPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Expanded(
          //       child: Text(
          //         sectionName, // Use the section name from Firebase
          //         style: TextStyle(
          //           fontSize: widget.screenWidth < 360 ? 14 : 16,
          //           fontWeight: FontWeight.bold,
          //           color: const Color(0xFF2D1B69),
          //         ),
          //         overflow: TextOverflow.ellipsis,
          //         maxLines: 1,
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     GestureDetector(
          //       onTap: () {
          //         // Navigate to category detail screen with section filter
          //         print(
          //             '[MART DYNAMIC SECTIONS] 🔗 Navigating to section: $sectionName');
          //         Get.to(() => MartCategoryDetailScreen(), arguments: {
          //           'categoryId':
          //               'section_${sectionName.toLowerCase().replaceAll(' ', '_')}',
          //           'categoryName': sectionName,
          //           'initialFilter': 'section',
          //           'sectionName': sectionName, // Pass the actual section name
          //         });
          //       },
          //       child: const Text(
          //         'See All >',
          //         style: TextStyle(
          //           fontSize: 16,
          //           color: Colors.blue,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 16),
          // Horizontal Scroll of Products using PlaytimeProductCard
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Consumer<MartProvider>(
              builder: (context, controller, _) {
                // Get products for this section from Firebase
                final sectionProducts = controller.getProductsForSection(
                  sectionName,
                );
                // If no products available, don't show anything (sections will appear as products load)
                if (sectionProducts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  height: 215,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sectionProducts.length,
                    itemBuilder: (context, index) {
                      final product = sectionProducts[index];
                      return PlaytimeProductCard(
                        volume: '${product.grams ?? 0}g',
                        productName: product.name,
                        discount: '${_calculateDiscount(product)}% OFF',
                        currentPrice: '₹${product.disPrice ?? product.price}',
                        originalPrice: '₹${product.price}',
                        screenWidth: widget.screenWidth,
                        imageUrl: product.photo,
                        product:
                            product, // Pass the product model for navigation
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDiscount(MartItemModel product) {
    if (product.disPrice != null && product.price > product.disPrice!) {
      return ((product.price - product.disPrice!) / product.price * 100)
          .round();
    }
    return 0;
  }
}

Widget searchWidgetMain() {
  /// Get appropriate icon for category based on name

  return Container(
    // width: 412,
    // height: 190,
    color: Colors.transparent,

    child: Column(
      children: [
        SizedBox(height: 16),

        // Group 262 - Search Bar
      ],
    ),
  );
}

// Helper method for user initials (keeping this one as it's still used)

// Dynamic Categories Section - Replaces dummy data sections
class MartDynamicCategoriesSection extends StatelessWidget {
  final double screenWidth;

  const MartDynamicCategoriesSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Consumer<MartProvider>(
      builder: (context, controller, _) {
        if (controller.isCategoryLoading) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  // Fixed overflow issue
                  children: List.generate(
                    8,
                    (index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.featuredCategories.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B69),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Categories Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
                // Fixed overflow issue
                children: controller.featuredCategories
                    .map(
                      (category) => _DynamicCategoryItem(
                        category: category,
                        onTap: () {
                          // Navigate to category detail screen
                          Get.to(
                            () => const MartCategoryDetailScreen(),
                            arguments: {
                              'categoryId': category.id,
                              'categoryName': category.title,
                            },
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DynamicCategoryItem extends StatelessWidget {
  final MartCategoryModel category;
  final VoidCallback? onTap;

  const _DynamicCategoryItem({required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category Image or Icon
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _parseColor(category.backgroundColor ?? '#E8E4FF'),
                ),
                child: category.photo != null && category.photo!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetworkImageWidget(
                          imageUrl: category.photo!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: _getCategoryIcon(category.title ?? ''),
                        ),
                      )
                    : _getCategoryIcon(category.title ?? ''),
              ),
            ),

            // Category Name
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  category.title ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D1B69),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String categoryName) {
    IconData icon;
    Color color;

    final name = categoryName.toLowerCase();

    if (name.contains('grocery') ||
        name.contains('vegetable') ||
        name.contains('fruit')) {
      icon = Icons.shopping_basket;
      color = Colors.green;
    } else if (name.contains('dairy') ||
        name.contains('milk') ||
        name.contains('bread')) {
      icon = Icons.egg;
      color = Colors.orange;
    } else if (name.contains('medicine') || name.contains('health')) {
      icon = Icons.local_pharmacy;
      color = Colors.red;
    } else if (name.contains('pet')) {
      icon = Icons.pets;
      color = Colors.brown;
    } else if (name.contains('electronics') || name.contains('mobile')) {
      icon = Icons.phone_android;
      color = Colors.blue;
    } else if (name.contains('clothing') || name.contains('fashion')) {
      icon = Icons.checkroom;
      color = Colors.purple;
    } else if (name.contains('home') || name.contains('furniture')) {
      icon = Icons.home;
      color = Colors.indigo;
    } else if (name.contains('sports') || name.contains('fitness')) {
      icon = Icons.sports_soccer;
      color = Colors.teal;
    } else {
      icon = Icons.category;
      color = Colors.grey;
    }

    return Icon(icon, size: 32, color: color);
  }
}

// Helper function to convert MartItemModel to PlaytimeProductCard format
PlaytimeProductCard _martItemToPlaytimeCard(
  MartItemModel item,
  double screenWidth,
) {
  // Calculate discount percentage
  String discount = '';
  if (item.disPrice != null && item.disPrice! < item.price) {
    double discountPercent = ((item.price - item.disPrice!) / item.price * 100)
        .round()
        .toDouble();
    discount = '${discountPercent.toInt()}% OFF';
  }

  // Get volume/weight from item attributes or use default
  String volume = item.weight ?? '1 pc';

  // Format prices
  String currentPrice =
      '₹${item.disPrice?.toStringAsFixed(0) ?? item.price.toStringAsFixed(0)}';
  String originalPrice = '₹${item.price.toStringAsFixed(0)}';

  return PlaytimeProductCard(
    volume: volume,
    productName: item.name,
    discount: discount,
    currentPrice: currentPrice,
    originalPrice: originalPrice,
    screenWidth: screenWidth,
    imageUrl: item.photo,
    product: item, // Pass the product model for cart functionality
  );
}
