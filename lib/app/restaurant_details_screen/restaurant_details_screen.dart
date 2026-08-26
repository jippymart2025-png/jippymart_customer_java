import 'dart:async';
import 'dart:math';

import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/PromotionalProductsSection.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restauant_product_list_view.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restaurant_detail_shimmer_widget.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_cupon_list_view.dart'
    hide resturantDetailsShimmer;
import 'package:jippymart_customer/app/review_list_screen/review_list_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../cart_check_out_page/cart_check_out_screen.dart';
import '../review_list_screen/provider/review_list_provider.dart';

const _kGradEnd = Color(0xFFff5201);

// ==================== CONSTANTS ====================
class _RestaurantScreenConstants {
  static const double scrollThreshold = 100.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration filterAnimationDuration = Duration(milliseconds: 200);
  static const double bottomModalHeightFactor = 0.35;
  static const double bottomModalWidthFactor = 0.7;
  static const double timingSheetHeightFactor = 0.70;

  // Height of the sticky search bar sliver
  static const double stickySearchBarHeight = 62.0;
}

Timer? _couponTimer;
int _couponIndex = 0;
bool responseToKeyboard = true;

// ==================== MAIN SCREEN ====================
class RestaurantDetailsScreen extends StatefulWidget {
  final String? scrollToProductId;
  final bool disableHero;

  const RestaurantDetailsScreen({
    super.key,
    this.scrollToProductId,
    this.disableHero = false,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late Animation<double> _titleOpacityAnimation;
  late Animation<Offset> _titleSlideAnimation;

  // Single scroll controller owned here and passed into the NestedScrollView
  // body via the provider. This avoids the double-scroll conflict entirely.
  late ScrollController _scrollController;

  bool _showTitle = false;
  bool _showStickySearch = false;

  // Threshold measured from the header card's render box after first layout
  double _headerCardHeight = 220.0;
  final GlobalKey _headerCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _initializeAnimations();
    _scrollController.addListener(_onScroll);

    _couponTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      final provider = context.read<RestaurantDetailsProvider>();

      if (provider.couponList.length <= 1) return;

      setState(() {
        _couponIndex = (_couponIndex + 1) % provider.couponList.length;
      });
    });
  }

  void _initializeAnimations() {
    _titleAnimationController = AnimationController(
      duration: _RestaurantScreenConstants.animationDuration,
      vsync: this,
    );

    _titleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _titleAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  double get _stickySearchThreshold {
    final renderBox =
        _headerCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      _headerCardHeight = renderBox.size.height;
    }
    return _headerCardHeight;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !mounted) return;

    final offset = _scrollController.offset;
    final shouldShowTitle = offset > _RestaurantScreenConstants.scrollThreshold;
    final shouldShowSearch = offset > _stickySearchThreshold;

    // Batch both state changes into a single setState to avoid double rebuilds
    if (shouldShowTitle != _showTitle ||
        shouldShowSearch != _showStickySearch) {
      setState(() {
        if (shouldShowTitle != _showTitle) {
          _showTitle = shouldShowTitle;
          if (_showTitle) {
            _titleAnimationController.forward();
          } else {
            _titleAnimationController.reverse();
          }
        }
        if (shouldShowSearch != _showStickySearch) {
          _showStickySearch = shouldShowSearch;
        }
      });
    }
  }

  @override
  void dispose() {
    _couponTimer?.cancel();

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _titleAnimationController.stop();
    _titleAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final controller = context.read<RestaurantDetailsProvider>();

    return Scaffold(
      backgroundColor: AppThemeData.surface,
      body: Padding(
        padding: EdgeInsets.only(
          bottom: responseToKeyboard
              ? (MediaQuery.of(context).viewInsets.bottom > 0
                    ? 0
                    : bottomSafeArea)
              : bottomSafeArea,
        ),
        child: RefreshIndicator(
          onRefresh: () => controller.getArgument(
            vendorModels: controller.vendorModel,
            forceRefresh: true,
          ),
          child: Selector<RestaurantDetailsProvider, bool>(
            selector: (_, p) => p.isLoading,
            builder: (context, isLoading, _) {
              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildAppBar(controller),
                  if (isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _RestaurantDetailsLoadingView(),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Selector<RestaurantDetailsProvider, String?>(
                        selector: (_, p) =>
                            '${p.vendorModel.id}|${p.vendorModel.title}|${p.couponList.length}|${p.isRestaurantFavorite}',
                        builder: (context, _, __) =>
                            _buildHeaderCard(context.read()),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickySearchDelegate(
                        controller: controller,
                        visible: _showStickySearch,
                        backgroundColor: _kGradEnd,
                        barHeight:
                            _RestaurantScreenConstants.stickySearchBarHeight,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SearchBarWidget(controller: controller),
                            const SizedBox(height: 10),
                            const PromotionalProductsSection(),
                            const SizedBox(height: 10),
                            _MenuSection(controller: controller),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    // canAccept is resolved when loading completes (same rebuild).
                    if (!context
                        .read<RestaurantDetailsProvider>()
                        .canAcceptOrders())
                      SliverToBoxAdapter(
                        child: _ClosedRestaurantMessage(
                          controller: context.read(),
                        ),
                      )
                    else
                      const ProductListView(),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// True only while the provider is loading. Once API returns (with or without products), show content or empty state.
  // Loading gate is handled via Selector on isLoading in build().

  // ==================== APP BAR ====================
  Widget _buildAppBar(RestaurantDetailsProvider controller) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _kGradEnd,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: _kGradEnd,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
      ),
      // Show elevation once user has scrolled past the header card
      elevation: _showStickySearch ? 0 : 0,
      // handled by sticky delegate shadow
      surfaceTintColor: Colors.transparent,
      title: _buildAppBarTitle(controller),
    );
  }

  Widget _buildAppBarTitle(RestaurantDetailsProvider controller) {
    return Row(
      children: [
        _buildBackButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Selector<RestaurantDetailsProvider, String>(
            selector: (_, p) => p.vendorModel.title ?? '',
            builder: (context, title, _) => AnimatedBuilder(
              animation: _titleAnimationController,
              builder: (context, _) => SlideTransition(
                position: _titleSlideAnimation,
                child: FadeTransition(
                  opacity: _titleOpacityAnimation,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeData.grey50,
                      fontFamily: AppThemeData.semiBold,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (Constant.userModel != null) _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Get.back(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.arrow_back, color: AppThemeData.grey50),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Selector<RestaurantDetailsProvider, bool>(
      selector: (_, provider) => provider.isRestaurantFavorite,
      builder: (context, isFavorite, child) {
        return AnimatedScale(
          scale: _showTitle ? 1.0 : 0.95,
          duration: _RestaurantScreenConstants.animationDuration,
          child: InkWell(
            onTap: () {
              context
                  .read<RestaurantDetailsProvider>()
                  .toggleRestaurantFavorite();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                isFavorite
                    ? "assets/icons/ic_like_fill.svg"
                    : "assets/icons/ic_like.svg",
                colorFilter: const ColorFilter.mode(
                  AppThemeData.grey50,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== HEADER CARD ====================
  Widget _buildHeaderCard(RestaurantDetailsProvider controller) {
    return RepaintBoundary(
      child: Container(
        key: _headerCardKey,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _kGradEnd,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppThemeData.grey50,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RestaurantHeader(
                controller: controller,
                disableHero: widget.disableHero,
              ),
              const SizedBox(height: 5),
              _StatusTimingRow(controller: controller),
              if (controller.couponList.isNotEmpty) ...[
                const SizedBox(height: 10),
                _CouponsSection(controller: controller),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomNavigationBar() {
    if (HomeProvider.cartItem.isEmpty) return null;

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        if (controller.couponList.isNotEmpty &&
            _couponIndex >= controller.couponList.length) {
          _couponIndex = 0;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Coupon Strip — compact single line, Zomato style
            if (controller.couponList.isNotEmpty)
              InkWell(
                onTap: () => _showCouponsBottomSheet(context, controller),
                child: Container(
                  height: 42,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEFD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF388E3C),
                          border: Border.all(
                            color: const Color(0xFF388E3C),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/svg/deals.gif',
                            // update to your actual asset path
                            width: 27,
                            height: 27,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey(_couponIndex),
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        "${controller.couponList[_couponIndex].code ?? ""}  •  ",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        controller
                                            .couponList[_couponIndex]
                                            .description ??
                                        "Special Offer",
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (controller.couponList.length > 1)
                        Text(
                          "+${controller.couponList.length - 1} more",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF388E3C),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF388E3C),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

            /// Cart Bar (unchanged)
            LayoutBuilder(
              builder: (context, constraints) {
                final sw = constraints.maxWidth;
                final isSmall = sw < 360;

                final fontSize = isSmall ? 14.0 : 15.5;
                final barHeight = isSmall ? 52.0 : 56.0;

                return InkWell(
                  onTap: () => Get.to(const CartCheckOutScreen()),
                  child: Container(
                    height: barHeight,
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF48000), Color(0xFFff0404)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: isSmall ? 18 : 20,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            '${HomeProvider.cartItem.length} ${'items'.tr}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Text(
                          'View Cart'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 4),

                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ==================== COUPONS BOTTOM SHEET ====================
  void _showCouponsBottomSheet(
    BuildContext context,
    RestaurantDetailsProvider controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          "Available Offers".tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: controller.couponList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final coupon = controller.couponList[index];
                        return _buildCouponCard(context, coupon);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCouponCard(BuildContext context, dynamic coupon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF388E3C),
            ),
            child: Center(
              child: Image.asset(
                'assets/svg/deals.gif',
                // update to your actual asset path
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code ?? "",
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coupon.description ?? "Special Offer",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Min Order: ${coupon.itemValue ?? 'N/A'}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: coupon.code ?? ""));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Coupon code copied".tr),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF388E3C),
              side: const BorderSide(color: Color(0xFF388E3C)),
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(38, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.content_copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  // ==================== FLOATING ACTION BUTTON ====================
  Widget _buildFloatingActionButton(RestaurantDetailsProvider controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: _RestaurantScreenConstants.animationDuration,
          child: IgnorePointer(
            ignoring: !_showTitle,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppThemeData.primary300,
                borderRadius: BorderRadius.circular(28),
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: AppThemeData.grey50,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: () => _MenuModal.show(context),
          backgroundColor: Colors.black,
          child: SvgPicture.asset(
            'assets/images/menu.svg',
            width: 44,
            height: 44,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ],
    );
  }
}

// ==================== STICKY SEARCH DELEGATE ====================
// Zero height when hidden — no layout space taken at all.
// Smoothly expands and pins below the AppBar when the header scrolls away.
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final RestaurantDetailsProvider controller;
  final bool visible;
  final Color backgroundColor;
  final double barHeight;

  const _StickySearchDelegate({
    required this.controller,
    required this.visible,
    required this.backgroundColor,
    required this.barHeight,
  });

  @override
  double get minExtent => visible ? barHeight : 0.0;

  @override
  double get maxExtent => visible ? barHeight : 0.0;

  @override
  bool shouldRebuild(_StickySearchDelegate old) =>
      old.visible != visible || old.controller != controller;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
      child: _SearchBarWidget(controller: controller, darkMode: true),
    );
  }
}

// ==================== SEARCH BAR WIDGET ====================
// darkMode = true  → white-on-colour (used in sticky sliver on primary bg)
// darkMode = false → dark-on-white  (used in white content area, default)
class _SearchBarWidget extends StatelessWidget {
  final RestaurantDetailsProvider controller;
  final bool darkMode;

  const _SearchBarWidget({required this.controller, this.darkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: darkMode ? Colors.white.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.90)
              : AppThemeData.grey200,
          width: 1,
        ),
        boxShadow: darkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: controller.searchEditingController,
        onChanged: controller.searchProduct,
        style: TextStyle(
          color: darkMode ? Colors.white : AppThemeData.grey900,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search dishes, meals and more...'.tr,
          hintStyle: TextStyle(
            color: darkMode
                ? Colors.white.withOpacity(0.6)
                : AppThemeData.grey400,
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              "assets/icons/ic_search.svg",
              colorFilter: ColorFilter.mode(
                darkMode ? Colors.white.withOpacity(0.8) : AppThemeData.grey500,
                BlendMode.srcIn,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ==================== RESTAURANT HEADER WIDGET ====================
class _RestaurantHeader extends StatelessWidget {
  final RestaurantDetailsProvider controller;
  final bool disableHero;

  const _RestaurantHeader({required this.controller, this.disableHero = false});

  Widget _buildContent(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.vendorModel.outletName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontFamily: AppThemeData.bold,
                    fontWeight: FontWeight.w600,
                    color: AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: Responsive.width(78, context),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppThemeData.grey500,
                        size: 14,
                      ),
                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          (Constant.selectedZone?.name?.isNotEmpty == true)
                              ? "${controller.vendorModel.location}, Locality"
                              : "Select Zone",
                          style: const TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                            color: AppThemeData.grey600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _RatingSection(controller: controller),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (disableHero) return content;
    return Hero(tag: 'restaurant_${controller.vendorModel.id}', child: content);
  }
}

// ==================== RATING SECTION ====================
class _RatingSection extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _RatingSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: ShapeDecoration(
            color: AppThemeData.primary50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(120),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                Constant.calculateReview(
                  reviewCount:
                      controller.vendorModel.review?.toStringAsFixed(0) ?? "0",
                  reviewSum: controller.vendorModel.review?.toString() ?? "0",
                ),
                style: const TextStyle(
                  color: AppThemeData.grey900,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Consumer<ReviewListProvider>(
          builder: (context, reviewListProvider, _) => InkWell(
            onTap: () {
              reviewListProvider.initFunction(
                vendorModels: controller.vendorModel,
              );
              Get.to(const ReviewListScreen());
            },
            child: Text(
              "${controller.vendorModel.reviewsCount ?? 0} ${'Ratings'.tr}",
              style: const TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: AppThemeData.grey500,
                color: AppThemeData.grey600,
                fontFamily: AppThemeData.regular,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== STATUS & TIMING ROW ====================
class _StatusTimingRow extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _StatusTimingRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusInfo = controller.getRestaurantStatusInfo();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppThemeData.grey100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppThemeData.grey200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusInfo['statusIcon'],
                color: AppThemeData.grey800,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                statusInfo['statusText'],
                style: const TextStyle(
                  color: AppThemeData.grey900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.circle, size: 5, color: AppThemeData.grey400),
        ),
        Expanded(
          child: Text(
            Constant.getDeliveryTimeText(controller.vendorModel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
              color: AppThemeData.grey900,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.circle, size: 5, color: AppThemeData.grey400),
        ),
        Flexible(
          child: InkWell(
            onTap: () => _handleViewTimings(context),
            child: Text(
              "View Timings".tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: AppThemeData.primary300,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
                color: AppThemeData.primary300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleViewTimings(BuildContext context) {
    final timings = controller.vendorModel.outletTimings;

    if (timings == null || timings.isEmpty) {
      ShowToastDialog.showToast("Timing is not added by restaurant".tr);
      return;
    }

    _TimingBottomSheet.show(context, controller);
  }
}

// ==================== COUPONS SECTION ====================
class _CouponsSection extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _CouponsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // const Text(
        //   "Additional Offers",
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontFamily: AppThemeData.semiBold,
        //     fontWeight: FontWeight.w600,
        //     color: AppThemeData.grey900,
        //   ),
        // ),
        CouponListView(controller: controller),
      ],
    );
  }
}

// ==================== MENU SECTION ====================
class _MenuSection extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _MenuSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu",
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppThemeData.semiBold,
            fontWeight: FontWeight.w600,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        _FilterChipsRow(controller: controller),
      ],
    );
  }
}

// ==================== FILTER CHIPS ROW ====================
class _FilterChipsRow extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _FilterChipsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Veg'.tr,
            isSelected: controller.isVag,
            icon: "assets/icons/ic_veg.svg",
            onTap: () {
              if (!controller.isVag) {
                controller.isVag = true;
                controller.isNonVag = false;
                controller.filterRecord();
              }
            },
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Non Veg'.tr,
            isSelected: controller.isNonVag,
            icon: "assets/icons/ic_nonveg.svg",
            onTap: () {
              if (!controller.isNonVag) {
                controller.isNonVag = true;
                controller.isVag = false;
                controller.filterRecord();
              }
            },
          ),
          const SizedBox(width: 6),
          // _OfferFilterChip(controller: controller),
          const SizedBox(width: 6),
          _ClearFilterButton(controller: controller),
        ],
      ),
    );
  }
}

// ==================== FILTER CHIP ====================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final String icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(120),
      child: AnimatedContainer(
        duration: _RestaurantScreenConstants.filterAnimationDuration,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: isSelected
            ? ShapeDecoration(
                color: AppThemeData.primary50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: AppThemeData.primary300),
                  borderRadius: BorderRadius.circular(120),
                ),
              )
            : ShapeDecoration(
                color: AppThemeData.grey100,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: AppThemeData.grey200),
                  borderRadius: BorderRadius.circular(120),
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(icon, height: 16, width: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppThemeData.grey800,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== OFFER FILTER CHIP ====================
class _OfferFilterChip extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _OfferFilterChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => controller.toggleOfferFilter(),
      borderRadius: BorderRadius.circular(120),
      child: AnimatedContainer(
        duration: _RestaurantScreenConstants.animationDuration,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: controller.isOfferFilter
            ? _selectedDecoration()
            : _unselectedDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer,
              size: 16,
              color: controller.isOfferFilter
                  ? Colors.white
                  : const Color(0xFFFF6B6B),
            ),
            const SizedBox(width: 4),
            Text(
              'Offers'.tr,
              style: TextStyle(
                color: controller.isOfferFilter
                    ? Colors.white
                    : const Color(0xFFFF6B6B),
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                shadows: controller.isOfferFilter
                    ? [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _selectedDecoration() => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFF6B6B)],
      stops: [0.0, 0.5, 1.0],
    ),
    borderRadius: BorderRadius.circular(120),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFFF6B6B).withOpacity(0.4),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
  );

  BoxDecoration _unselectedDecoration() => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        const Color(0xFFFF6B6B).withOpacity(0.08),
        const Color(0xFFFF8E53).withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(120),
    border: Border.all(
      color: const Color(0xFFFF6B6B).withOpacity(0.3),
      width: 1.5,
    ),
  );
}

// ==================== CLEAR FILTER BUTTON ====================
class _ClearFilterButton extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _ClearFilterButton({required this.controller});

  bool get _hasActiveFilters =>
      controller.isVag ||
      controller.isNonVag ||
      controller.isOfferFilter ||
      controller.searchEditingController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    return AnimatedScale(
      scale: 1.0,
      duration: _RestaurantScreenConstants.filterAnimationDuration,
      child: InkWell(
        onTap: () {
          try {
            controller.clearAllFilters();
          } catch (e) {
            debugPrint('Error clearing filters: $e');
          }
        },
        borderRadius: BorderRadius.circular(120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppThemeData.grey200,
            borderRadius: BorderRadius.circular(120),
            border: Border.all(width: 1, color: AppThemeData.grey300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear, size: 16, color: AppThemeData.grey800),
              const SizedBox(width: 4),
              Text(
                'Clear'.tr,
                style: TextStyle(
                  color: AppThemeData.grey800,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CLOSED RESTAURANT MESSAGE ====================
class _ClosedRestaurantMessage extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const _ClosedRestaurantMessage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusInfo = controller.getRestaurantStatusInfo();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.lock, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text(
              'This restaurant is currently closed.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusInfo['reason'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (statusInfo['nextOpeningTime'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next opening: ${statusInfo['nextOpeningTime']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== MENU MODAL ====================
class _MenuModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.only(bottom: 50, left: 20, right: 40),
                height:
                    MediaQuery.of(context).size.height *
                    _RestaurantScreenConstants.bottomModalHeightFactor,
                width:
                    MediaQuery.of(context).size.width *
                    _RestaurantScreenConstants.bottomModalWidthFactor,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Consumer<RestaurantDetailsProvider>(
                  builder: (context, controller, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ListView.builder(
                      itemCount: controller.vendorCategoryList.length,
                      itemBuilder: (context, index) {
                        final category = controller.vendorCategoryList[index];
                        final productCount = controller
                            .getProductsByCategory(category.id.toString())
                            .length;
                        return _MenuItem(
                          title: category.title ?? "",
                          count: productCount,
                          onTap: () {
                            Navigator.pop(context);
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () => controller.scrollToCategory(index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MENU ITEM ====================
class _MenuItem extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  final bool isNew;

  const _MenuItem({
    required this.title,
    required this.count,
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$count items',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TIMING BOTTOM SHEET ====================
// ==================== TIMING BOTTOM SHEET ====================

class _TimingBottomSheet {
  static void show(BuildContext context, RestaurantDetailsProvider controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: _RestaurantScreenConstants.timingSheetHeightFactor,
          child: Scaffold(
            backgroundColor: AppThemeData.surface,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildHandle(),
                  Expanded(child: _buildTimingList(controller)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: ShapeDecoration(
            color: AppThemeData.grey800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTimingList(RestaurantDetailsProvider controller) {
    final timings = controller.vendorModel.outletTimings;

    if (timings == null || timings.isEmpty) {
      return const Center(
        child: Text(
          'No timings available',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: timings.length,
      itemBuilder: (context, dayIndex) {
        final OutletTiming timing = timings[dayIndex];

        return _TimingDayItem(outletTiming: timing);
      },
    );
  }
}

// ==================== TIMING DAY ITEM ====================

class _TimingDayItem extends StatelessWidget {
  final OutletTiming outletTiming;

  const _TimingDayItem({required this.outletTiming});

  @override
  Widget build(BuildContext context) {
    final bool isOpen = outletTiming.isOpen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // DAY
          // --------------------------------------------------
          Text(
            outletTiming.day,
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
              color: AppThemeData.grey900,
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------
          // CLOSED
          // --------------------------------------------------
          if (!isOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemeData.grey200),
              ),
              child: const Center(
                child: Text(
                  'Closed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          // --------------------------------------------------
          // OPEN
          // --------------------------------------------------
          else
            _TimeSlotItem(
              openingTime: outletTiming.openingTime ?? '',
              closingTime: outletTiming.closingTime ?? '',
            ),
        ],
      ),
    );
  }
}

// ==================== TIME SLOT ITEM ====================

class _TimeSlotItem extends StatelessWidget {
  final String openingTime;
  final String closingTime;

  const _TimeSlotItem({required this.openingTime, required this.closingTime});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildTimeBox(openingTime)),

        const SizedBox(width: 10),

        Expanded(child: _buildTimeBox(closingTime)),
      ],
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeData.grey200),
      ),
      child: Center(
        child: Text(
          _formatTime(time),
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 14,
            color: AppThemeData.grey500,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FORMAT 24-HOUR TIME
  // 09:00:00 -> 09:00 AM
  // 20:00:00 -> 08:00 PM
  // ==========================================================

  String _formatTime(String time) {
    if (time.isEmpty) {
      return '--';
    }

    try {
      final parts = time.split(':');

      if (parts.length < 2) {
        return time;
      }

      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      final String period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} '
          '$period';
    } catch (_) {
      return time;
    }
  }
}

/// Full-screen loading view: card with spinner and text only (no skeleton).
class _RestaurantDetailsLoadingView extends StatelessWidget {
  const _RestaurantDetailsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppThemeData.surface,
      child: Center(child: _LoadingCard()),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: AppThemeData.grey50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.primary300.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppThemeData.primary300,
                  ),
                  backgroundColor: AppThemeData.primary50,
                ),
                Icon(
                  Icons.restaurant_rounded,
                  size: 26,
                  color: AppThemeData.primary300.withOpacity(0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading restaurant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Getting the menu ready...',
            style: TextStyle(
              fontSize: 13,
              color: AppThemeData.grey500,
              fontFamily: AppThemeData.regular,
            ),
          ),
        ],
      ),
    );
  }
}
