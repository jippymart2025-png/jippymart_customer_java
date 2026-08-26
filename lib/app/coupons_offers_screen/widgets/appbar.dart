import 'package:flutter/material.dart';
import '../../Communityscreen/theme/app_theme.dart';

Widget buildCouponsAppBar(BuildContext context) {
  return Container(
    height: 60,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F1F3), width: 1)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF5F6F8),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Coupons & Offers',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    ),
  );
}
