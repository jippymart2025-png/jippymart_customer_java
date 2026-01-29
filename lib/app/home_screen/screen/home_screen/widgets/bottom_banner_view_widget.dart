import 'package:flutter/material.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/network_image_widget.dart';

class BottomBannerView extends StatefulWidget {
  const BottomBannerView({super.key});

  @override
  State<BottomBannerView> createState() => _BottomBannerViewState();
}

class _BottomBannerViewState extends State<BottomBannerView> {
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timerStarted && mounted) {
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        if (homeProvider.bannerBottomModel.isNotEmpty &&
            homeProvider.pageBottomController.hasClients) {
          homeProvider.startBottomBannerTimer();
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
              homeProvider.bannerBottomModel.isNotEmpty &&
              homeProvider.pageBottomController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_timerStarted) {
                homeProvider.startBottomBannerTimer();
                _timerStarted = true;
              }
            });
          }

          return GestureDetector(
            onPanStart: (_) => homeProvider.stopBottomBannerTimer(),
            onPanEnd: (_) => homeProvider.startBottomBannerTimer(),
            child: PageView.builder(
              physics: const BouncingScrollPhysics(),
              controller: homeProvider.pageBottomController,
              scrollDirection: Axis.horizontal,
              itemCount: homeProvider.bannerBottomModel.length,
              padEnds: false,
              pageSnapping: true,
              onPageChanged: (value) {
                homeProvider.changeBottomBannerPage(value);
              },
              itemBuilder: (BuildContext context, int index) {
                BannerModel bannerModel = homeProvider.bannerBottomModel[index];
                final isLastItem = index == homeProvider.bannerBottomModel.length - 1;
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

