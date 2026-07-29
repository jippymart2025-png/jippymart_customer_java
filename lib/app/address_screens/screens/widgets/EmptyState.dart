import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';
import 'AddressFormSheet.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAddNew;

  const EmptyState({required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Tokens.sp28),
      decoration: BoxDecoration(
        color: Tokens.card,
        borderRadius: BorderRadius.circular(Tokens.rXXL),
        border: Border.all(color: Tokens.cardBorder),
        boxShadow: Tokens.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Layered icon visual
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Tokens.orangeChip,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: kBrandGradient,
                  borderRadius: BorderRadius.circular(Tokens.rXL),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.sp20),
          Text(
            "No saved addresses yet".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: Tokens.textXL,
              color: Tokens.textPrimary,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Tokens.sp8),
          Text(
            "Add your first delivery location to speed up checkout and make switching between places easier."
                .tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: Tokens.textSM,
              height: 1.55,
              color: Tokens.textMuted,
              fontFamily: AppThemeData.regular,
            ),
          ),
          const SizedBox(height: Tokens.sp24),
          // Gradient CTA button
          GradientButton(
            label: "Add Your First Address".tr,
            icon: Icons.add_location_alt_rounded,
            onTap: onAddNew,
          ),
        ],
      ),
    );
  }
}
