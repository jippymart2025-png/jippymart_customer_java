import 'package:flutter/material.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/network_image_widget.dart';

class BannerView extends StatelessWidget {
  const BannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Consumer2<RestaurantDetailsProvider, HomeProvider>(
        builder: (context, restaurantDetailsProvider, homeProvider, _) {
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
                return InkWell(
                  onTap: () async {
                    homeProvider.bannerOnTapFunction(
                      bannerModel,
                      restaurantDetailsProvider,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 0),
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
