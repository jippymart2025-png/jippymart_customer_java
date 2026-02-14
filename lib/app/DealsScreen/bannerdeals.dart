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

class DealsBannerView extends StatefulWidget {
  final List<BannerModel> banners;
  final bool autoPlay;

  const DealsBannerView({required this.banners, this.autoPlay = true});

  @override
  State<DealsBannerView> createState() => _DealsBannerViewState();
}

class _DealsBannerViewState extends State<DealsBannerView> {
  late PageController _pageController;
  Timer? _bannerTimer;
  int _currentPage = 0;
  bool _isPageAnimating = false;
  static const Duration _bannerDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPlay && widget.banners.length > 1) {
        _startBannerTimer();
      }
    });
  }

  @override
  void didUpdateWidget(DealsBannerView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only restart timer if banners actually changed
    if (oldWidget.banners.length != widget.banners.length &&
        widget.banners.length > 1 &&
        widget.autoPlay) {
      _stopBannerTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startBannerTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _stopBannerTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();

    if (widget.banners.length <= 1 || !widget.autoPlay) {
      return;
    }

    if (!_pageController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _pageController.hasClients) {
          _startBannerTimer();
        }
      });
      return;
    }

    _bannerTimer = Timer.periodic(_bannerDuration, (timer) {
      if (!mounted || !_pageController.hasClients || _isPageAnimating) {
        timer.cancel();
        return;
      }

      if (widget.banners.length <= 1) {
        timer.cancel();
        return;
      }

      int nextPage = _currentPage + 1;
      if (nextPage >= widget.banners.length) {
        nextPage = 0;
      }

      setState(() {
        _currentPage = nextPage;
      });

      try {
        _isPageAnimating = true;
        _pageController
            .animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            )
            .then((_) {
              _isPageAnimating = false;
            });
      } catch (e) {
        _isPageAnimating = false;
        timer.cancel();
      }
    });
  }

  void _stopBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
  }

  Future<void> _onBannerTap(BannerModel bannerModel) async {
    _stopBannerTimer();

    final restaurantDetailsProvider = Provider.of<RestaurantDetailsProvider>(
      context,
      listen: false,
    );

    if (bannerModel.redirectType == "store") {
      ShowToastDialog.showLoader("Please wait".tr);
      try {
        final vendorModel = await FireStoreUtils.getVendorById(
          bannerModel.redirectId.toString(),
        );

        if (vendorModel?.zoneId == Constant.selectedZone?.id) {
          ShowToastDialog.closeLoader();
          restaurantDetailsProvider.initFunction(
            vendorModels: vendorModel ?? VendorModel(),
          );
          Get.to(() => const RestaurantDetailsScreen());
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "This store is not available in your area.".tr,
          );
        }
      } catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Error loading store details".tr);
      }
    } else if (bannerModel.redirectType == "product") {
      ShowToastDialog.showLoader("Please wait".tr);
      try {
        final productModel = await FireStoreUtils.getProductById(
          bannerModel.redirectId.toString(),
        );

        if (productModel != null) {
          final vendorModel = await FireStoreUtils.getVendorById(
            productModel.vendorID.toString(),
          );

          if (vendorModel?.zoneId == Constant.selectedZone?.id) {
            ShowToastDialog.closeLoader();
            restaurantDetailsProvider.initFunction(vendorModels: vendorModel!);
            Get.to(() => const RestaurantDetailsScreen());
          } else {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
              "This product is not available in your area.".tr,
            );
          }
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Product not found".tr);
        }
      } catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Error loading product details".tr);
      }
    } else if (bannerModel.redirectType == "external_link") {
      final uri = Uri.parse(bannerModel.redirectId.toString());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ShowToastDialog.showToast("Could not open link".tr);
      }
    }

    if (widget.autoPlay && widget.banners.length > 1) {
      _startBannerTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 160,
      child: GestureDetector(
        onPanStart: (_) => _stopBannerTimer(),
        onPanEnd: (_) {
          if (widget.autoPlay && widget.banners.length > 1) {
            _startBannerTimer();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              physics: const BouncingScrollPhysics(),
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.banners.length,
              padEnds: false,
              pageSnapping: true,
              onPageChanged: (value) {
                setState(() {
                  _currentPage = value;
                });
              },
              itemBuilder: (BuildContext context, int index) {
                final bannerModel = widget.banners[index];
                final isLastItem = index == widget.banners.length - 1;

                return InkWell(
                  onTap: () => _onBannerTap(bannerModel),
                  child: Padding(
                    padding: EdgeInsets.only(right: isLastItem ? 0 : 8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: NetworkImageWidget(
                        imageUrl: bannerModel.photo.toString(),
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Page indicators - only show if more than 1 banner
            if (widget.banners.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.banners.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
