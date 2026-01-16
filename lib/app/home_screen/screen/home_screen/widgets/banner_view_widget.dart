import 'package:flutter/material.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/network_image_widget.dart';

class BannerView extends StatefulWidget {
  const BannerView({super.key});

  @override
  State<BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<BannerView> {
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timerStarted && mounted) {
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        if (homeProvider.bannerModel.isNotEmpty &&
            homeProvider.pageController.hasClients) {
          homeProvider.startBannerTimer();
          _timerStarted = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Consumer2<RestaurantDetailsProvider, HomeProvider>(
        builder: (context, restaurantDetailsProvider, homeProvider, _) {
          // Ensure timer starts when banners become available and PageController is ready
          if (!_timerStarted &&
              homeProvider.bannerModel.isNotEmpty &&
              homeProvider.pageController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_timerStarted) {
                homeProvider.startBannerTimer();
                _timerStarted = true;
              }
            });
          }

          return GestureDetector(
            onPanStart: (_) => homeProvider.stopBannerTimer(),
            onPanEnd: (_) => homeProvider.startBannerTimer(),
            child: PageView.builder(
              physics: const BouncingScrollPhysics(),
              controller: homeProvider.pageController,
              scrollDirection: Axis.horizontal,
              itemCount: homeProvider.bannerModel.length,
              padEnds: false,
              pageSnapping: true,
              onPageChanged: (value) {
                homeProvider.changeBannerPage(value);
              },
              itemBuilder: (BuildContext context, int index) {
                BannerModel bannerModel = homeProvider.bannerModel[index];
                final isLastItem = index == homeProvider.bannerModel.length - 1;
                return InkWell(
                  onTap: () async {
                    homeProvider.bannerOnTapFunction(
                      bannerModel,
                      restaurantDetailsProvider,
                    );
                  },
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
          );
        },
      ),
    );
  }
}
