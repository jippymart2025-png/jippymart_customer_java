import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
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

  const DealsBannerView({required this.banners});

  @override
  State<DealsBannerView> createState() => _DealsBannerViewState();
}

class _DealsBannerViewState extends State<DealsBannerView> {
  late PageController _pageController;
  Timer? _bannerTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Start timer after the first frame when PageController has clients
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBannerTimer();
    });
  }

  @override
  void didUpdateWidget(DealsBannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if banners list changed
    if (oldWidget.banners.length != widget.banners.length) {
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
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    
    // Don't start timer if no banners or only one banner
    if (widget.banners.isEmpty || widget.banners.length <= 1) {
      return;
    }
    
    // Wait for PageController to have clients
    if (!_pageController.hasClients) {
      // Retry after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _pageController.hasClients) {
          _startBannerTimer();
        }
      });
      return;
    }

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients) {
        timer.cancel();
        return;
      }
      
      if (widget.banners.isEmpty || widget.banners.length <= 1) {
        timer.cancel();
        return;
      }

      int nextPage = _currentPage + 1;
      if (nextPage >= widget.banners.length) {
        nextPage = 0;
      }

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
        });
        
        try {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _stopBannerTimer() {
    _bannerTimer?.cancel();
  }

  void _onBannerTap(BannerModel bannerModel) async {
    _stopBannerTimer();
    final restaurantDetailsProvider = Provider.of<RestaurantDetailsProvider>(
      context,
      listen: false,
    );

    if (bannerModel.redirectType == "store") {
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        bannerModel.redirectId.toString(),
      );
      if (vendorModel?.zoneId == Constant.selectedZone?.id) {
        ShowToastDialog.closeLoader();
        restaurantDetailsProvider.initFunction(
          vendorModels: vendorModel ?? VendorModel(),
        );
        Get.to(const RestaurantDetailsScreen());
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Sorry, The Zone is not available in your area. change the other location first.",
        );
      }
    } else if (bannerModel.redirectType == "product") {
      ShowToastDialog.showLoader("Please wait");
      ProductModel? productModel = await FireStoreUtils.getProductById(
        bannerModel.redirectId.toString(),
      );
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        productModel!.vendorID.toString(),
      );
      if (vendorModel!.zoneId == Constant.selectedZone!.id) {
        ShowToastDialog.closeLoader();
        restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
        Get.to(const RestaurantDetailsScreen());
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          "Sorry, The Zone is not available in your area. change the other location first."
              .tr,
        );
      }
    } else if (bannerModel.redirectType == "external_link") {
      final uri = Uri.parse(bannerModel.redirectId.toString());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ShowToastDialog.showToast("Could not launch".tr);
      }
    }
    _startBannerTimer();
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
        onPanEnd: (_) => _startBannerTimer(),
        child: PageView.builder(
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
            // Restart timer after manual page change
            _stopBannerTimer();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _startBannerTimer();
              }
            });
          },
          itemBuilder: (BuildContext context, int index) {
            BannerModel bannerModel = widget.banners[index];
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
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
