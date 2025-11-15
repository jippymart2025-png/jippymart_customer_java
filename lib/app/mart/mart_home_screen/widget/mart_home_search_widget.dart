import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/mart/mart_search_screen.dart';
import 'package:jippymart_customer/widget/animated_search_hint.dart';

Widget homeSearchWidget() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
      onTap: () {
        Get.to(() => const MartSearchScreen());
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
          "Search 'milk'",
          "Search 'bread'",
          "Search 'rice'",
          "Search 'atta'",
          "Search 'oil'",
          "Search 'sugar'",
          "Search 'tea'",
          "Search 'coffee'",
          "Search 'snacks'",
          "Search 'biscuits'",
          "Search 'cold drinks'",
          "Search 'toothpaste'",
          "Search 'detergent'",
          "Search 'shampoo'",
          "Search 'soap'",
          "Search 'cleaning supplies'",
          "Search 'baby care'",
          "Search 'personal care'",
          "Search 'frozen food'",
          "Search 'fresh vegetables'",
          "Search 'fruits'",
          "Search 'eggs'",
          "Search 'dry fruits'",
          "Search 'masala'",
          "Search 'instant food'",
          "Search 'breakfast items'",
          "Search 'stationery'",
          "Search 'pet food'",
          "Search 'household essentials'",
          "Search 'kitchen items'",
          "Search 'offers near you'",
          "Search 'best deals'",
          "Search 'today’s discount'",
          "Search 'new arrivals'",
          "Search 'bestsellers'",
        ],
        interval: const Duration(seconds: 2),
      ),
    ),
  );
}
