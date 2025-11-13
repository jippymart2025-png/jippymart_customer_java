import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/provider/swiggy_search_provider.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/swiggy_search_screen.dart';
import 'package:jippymart_customer/widget/animated_search_hint.dart';
import 'package:provider/provider.dart';

Widget homeScreenSearchWidget() {
  return Consumer<SwiggySearchProvider>(
    builder: (context, swiggySearchProvider, _) {
      return InkWell(
        onTap: () {
          swiggySearchProvider.initFunction();
          Get.to(() => const SwiggySearchScreen());
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SvgPicture.asset(
              "assets/icons/ic_search.svg",
              color: Color(0xFFff5201),
            ),
          ),
          hints: [
            // Food items
            "Search 'cake'",
            "Search 'biryani'",
            "Search 'ice cream'",
            "Search 'pizza'",
            "Search 'burger'",
            "Search 'sushi'",
            "Search 'restaurants'",
            "Search 'curry'",
            "Search 'noodles'",
            "Search 'tacos'",
            "Search 'chicken'",
            "Search 'salad'",
            "Search 'breakfast'",
            "Search 'pasta'",
            "Search 'soup'",
            "Search 'wraps'",
            "Search 'donuts'",
            "Search 'coffee'",
            "Search 'cookies'",
            "Search 'drinks'",

            // Motivational messages
            "Search 'healthy food'",
            "Search 'trending dishes'",
            "Search 'popular items'",
            "Search 'top rated'",
            "Search 'new arrivals'",
            "Search 'premium'",
            "Search 'best deals'",
            "Search 'award winning'",
            "Search 'special offers'",
            "Search 'today's special'",
            "Search 'gift ideas'",
            "Search 'late night'",
            "Search 'morning'",
            "Search 'evening'",
            "Search 'dinner'",
            "Search 'family meals'",
            "Search 'group orders'",
            "Search 'office lunch'",
            "Search 'party food'",
          ],
          interval: const Duration(seconds: 2),
        ),
      );
    },
  );
}
