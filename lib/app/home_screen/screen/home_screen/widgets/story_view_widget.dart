import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/story_view_screen/story_view.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/story_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/widget/gradiant_text.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:provider/provider.dart';

class StoryView extends StatelessWidget {
  final HomeProvider controller;

  const StoryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Responsive.height(32, context),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Stories",
                        style: TextStyle(
                          fontFamily: AppThemeData.montserrat,
                          color: AppThemeData.success400,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                GradientText(
                  'Best deals only for you ${Constant.userModel?.firstName.toString()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: AppThemeData.montserrat,
                    fontWeight: FontWeight.w800,
                  ),
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1C839), Color(0xFFEA1111)],
                  ),
                ),
              ],
            ),
          ),
          Consumer<BestRestaurantProvider>(
            builder: (context, bestRestaurantProvider, _) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: bestRestaurantProvider.storyList.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      StoryModel storyModel =
                          bestRestaurantProvider.storyList[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () {
                            log(
                              bestRestaurantProvider.storyList[index].videoUrls
                                  .toString(),
                              name: "storyList ",
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MoreStories(
                                  storyList: bestRestaurantProvider.storyList,
                                  index: index,
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 134,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  NetworkImageWidget(
                                    imageUrl: storyModel.videoThumbnail
                                        .toString(),
                                    fit: BoxFit.cover,
                                    height: Responsive.height(100, context),
                                    width: Responsive.width(100, context),
                                  ),
                                  Container(
                                    color: Colors.black.withOpacity(0.30),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 8,
                                    ),
                                    child: FutureBuilder(
                                      future: FireStoreUtils.getVendorById(
                                        storyModel.vendorID.toString(),
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Constant.loader();
                                        } else {
                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error: ${snapshot.error}',
                                              ),
                                            );
                                          } else if (snapshot.data == null) {
                                            return const SizedBox();
                                          } else {
                                            VendorModel vendorModel =
                                                snapshot.data!;
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipOval(
                                                  child:
                                                      RestaurantImageWithStatus(
                                                        vendorModel:
                                                            vendorModel,
                                                        width: 30,
                                                        height: 30,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        vendorModel.title
                                                            .toString(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                            "assets/icons/ic_star.svg",
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum!.toStringAsFixed(0))} ${'reviews'}",
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            style: const TextStyle(
                                                              color: AppThemeData
                                                                  .warning300,
                                                              fontSize: 10,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
