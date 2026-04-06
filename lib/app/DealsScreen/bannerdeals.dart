import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constant/constant.dart';
import '../../constant/show_toast_dialog.dart';
import '../../models/BannerModel.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../utils/fire_store_utils.dart';
import '../../utils/network_image_widget.dart';
import '../restaurant_details_screen/provider/restaurant_details_provider.dart';
import '../restaurant_details_screen/restaurant_details_screen.dart';

// Fallback gradient configs for banners without images
const List<List<Color>> _kBannerGradients = [
  [Color(0xFFD12477), Color(0xFF8E1552)],
  [Color(0xFF6C3BE4), Color(0xFF3B0FA8)],
  [Color(0xFFFF6B35), Color(0xFFD12477)],
  [Color(0xFF00B4D8), Color(0xFF0077B6)],
  [Color(0xFF2D6A4F), Color(0xFF1B4332)],
];

class DealsBannerView extends StatefulWidget {
  final List<BannerModel> banners;
  final bool autoPlay;

  const DealsBannerView({
    super.key,
    required this.banners,
    this.autoPlay = true,
  });

  @override
  State<DealsBannerView> createState() => _DealsBannerViewState();
}

class _DealsBannerViewState extends State<DealsBannerView>
    with SingleTickerProviderStateMixin {
  late PageController _pageCtrl;
  Timer? _timer;
  int _currentPage = 0;
  bool _animating = false;

  static const Duration _interval = Duration(seconds: 4);
  static const Duration _animDuration = Duration(milliseconds: 480);

  // For animated indicator
  late AnimationController _indicatorAnim;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.95);
    _indicatorAnim = AnimationController(vsync: this, duration: _interval);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPlay && widget.banners.length > 1) {
        _startTimer();
        _indicatorAnim.forward();
      }
    });
  }

  @override
  void didUpdateWidget(DealsBannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length &&
        widget.banners.length > 1 &&
        widget.autoPlay) {
      _stopTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _pageCtrl.dispose();
    _indicatorAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.banners.length <= 1 || !widget.autoPlay) return;
    if (!_pageCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _pageCtrl.hasClients) _startTimer();
      });
      return;
    }
    _indicatorAnim.reset();
    _indicatorAnim.forward();
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_pageCtrl.hasClients || _animating) return;
      if (widget.banners.length <= 1) return;
      final next = (_currentPage + 1) % widget.banners.length;
      _animating = true;
      _pageCtrl
          .animateToPage(
            next,
            duration: _animDuration,
            curve: Curves.easeInOutCubic,
          )
          .then((_) => _animating = false);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _indicatorAnim.stop();
  }

  Future<void> _onTap(BannerModel banner) async {
    _stopTimer();
    final provider = Provider.of<RestaurantDetailsProvider>(
      context,
      listen: false,
    );

    if (banner.redirectType == 'store') {
      ShowToastDialog.showLoader('Please wait'.tr);
      try {
        final vendor = await FireStoreUtils.getVendorById(
          banner.redirectId.toString(),
        );
        ShowToastDialog.closeLoader();
        if (vendor?.zoneId == Constant.selectedZone?.id) {
          provider.initFunction(vendorModels: vendor ?? VendorModel());
          Get.to(() => const RestaurantDetailsScreen());
        } else {
          ShowToastDialog.showToast(
            'This store is not available in your area.'.tr,
          );
        }
      } catch (_) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Error loading store details'.tr);
      }
    } else if (banner.redirectType == 'product') {
      ShowToastDialog.showLoader('Please wait'.tr);
      try {
        final product = await FireStoreUtils.getProductById(
          banner.redirectId.toString(),
        );
        if (product != null) {
          final vendor = await FireStoreUtils.getVendorById(
            product.vendorID.toString(),
          );
          ShowToastDialog.closeLoader();
          if (vendor?.zoneId == Constant.selectedZone?.id) {
            provider.initFunction(vendorModels: vendor!);
            Get.to(() => const RestaurantDetailsScreen());
          } else {
            ShowToastDialog.showToast(
              'This product is not available in your area.'.tr,
            );
          }
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast('Product not found'.tr);
        }
      } catch (_) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Error loading product details'.tr);
      }
    } else if (banner.redirectType == 'external_link') {
      final uri = Uri.tryParse(banner.redirectId.toString());
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ShowToastDialog.showToast('Could not open link'.tr);
      }
    }

    if (widget.autoPlay && widget.banners.length > 1) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner carousel
        SizedBox(
          height: 160,
          child: GestureDetector(
            onPanStart: (_) {
              _stopTimer();
            },
            onPanEnd: (_) {
              if (widget.autoPlay && widget.banners.length > 1) _startTimer();
            },
            child: PageView.builder(
              controller: _pageCtrl,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.banners.length,
              onPageChanged: (v) {
                setState(() => _currentPage = v);
                _indicatorAnim.reset();
                _indicatorAnim.forward();
              },
              itemBuilder: (ctx, i) {
                final banner = widget.banners[i];
                final gradColors =
                    _kBannerGradients[i % _kBannerGradients.length];
                final isFirst = i == 0;
                final isLast = i == widget.banners.length - 1;

                return AnimatedScale(
                  scale: _currentPage == i ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Padding(
                    // padding: EdgeInsets.only(
                    //   left: isFirst ? 0 : 6,
                    //   right: isLast ? 0 : 6,
                    // ),
                    padding: EdgeInsets.zero,
                    child: GestureDetector(
                      onTap: () => _onTap(banner),
                      child: _BannerCard(
                        banner: banner,
                        gradColors: gradColors,
                        index: i,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          // Dot indicators
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.banners.length, (i) {
                final isActive = _currentPage == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? const Color(0xFFD12477)
                        : const Color(0xFFD8D2EC),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Individual Banner Card ────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final List<Color> gradColors;
  final int index;

  const _BannerCard({
    required this.banner,
    required this.gradColors,
    required this.index,
  });

  bool _hasValidPhoto() {
    final p = banner.photo?.toString().trim();
    if (p == null || p.isEmpty || p == 'null') return false;
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: real image or gradient fallback
          if (_hasValidPhoto())
            NetworkImageWidget(
              imageUrl: banner.photo!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fill,
            )
          else
            _GradientBackground(colors: gradColors, index: index),

          // Overlay for text legibility
          if (_hasValidPhoto())
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                ),
              ),
            ),

          // Text content (shown over gradient or image)
          if (!_hasValidPhoto() || _hasTextContent())
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              right: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_eyebrow().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _eyebrow(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  if (_eyebrow().isNotEmpty) const SizedBox(height: 6),
                  Text(
                    _headline(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Shop Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: gradColors.first,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: gradColors.first,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _hasTextContent() => false; // Only show text on gradient cards

  String _eyebrow() {
    switch (index % 3) {
      case 0:
        return 'FLASH SALE';
      case 1:
        return 'FREE DELIVERY';
      default:
        return 'WEEKEND OFFER';
    }
  }

  String _headline() {
    switch (index % 3) {
      case 0:
        return 'Up to 50%\nOFF Today';
      case 1:
        return 'Orders above\n₹199';
      default:
        return 'Combo meals\nfrom ₹99';
    }
  }
}

// ── Animated Gradient Background ─────────────────────────────────
class _GradientBackground extends StatelessWidget {
  final List<Color> colors;
  final int index;

  const _GradientBackground({required this.colors, required this.index});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -25,
          right: -25,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -55,
          right: 50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 90,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x40FFFFFF),
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          right: 30,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x30FFFFFF),
            ),
          ),
        ),
      ],
    );
  }
}
