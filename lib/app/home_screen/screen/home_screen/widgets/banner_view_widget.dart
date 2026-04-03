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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      if (homeProvider.bannerModel.isNotEmpty) {
        // Precache first image for iOS
        final firstBanner = homeProvider.bannerModel.first;
        final imageUrl = firstBanner.photo.toString();
        if (imageUrl.isNotEmpty && imageUrl != "null") {
          try {
            final image = Image.network(imageUrl, fit: BoxFit.cover);
            precacheImage(image.image, context);
          } catch (e) {
            print('Error precaching banner image: $e');
          }
        }

        // Force initial page
        if (homeProvider.pageController.hasClients) {
          homeProvider.pageController.jumpToPage(0);
        }

        // Start timer with delay
        await Future.delayed(const Duration(milliseconds: 150));
        homeProvider.startBannerTimer();
        _timerStarted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          // This should be inside the builder function, not outside
          if (!_timerStarted && homeProvider.bannerModel.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted && !_timerStarted) {
                // Force initial page for iOS
                if (homeProvider.pageController.hasClients) {
                  homeProvider.pageController.jumpToPage(0);
                }

                await Future.delayed(const Duration(milliseconds: 100));
                homeProvider.startBannerTimer();
                _timerStarted = true;
              }
            });
          }

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
                    final restaurantDetailsProvider = context
                        .read<RestaurantDetailsProvider>();
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
                        width: MediaQuery.of(context).size.width,
                        height: 160,
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
