import 'package:flutter/cupertino.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';
import 'AddressFormSheet.dart';

class SectionHeader extends StatelessWidget {
  final int count;

  const SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Accent bar
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Tokens.sp10),
        Expanded(
          child: Text(
            "Saved Addresses".tr,
            style: const TextStyle(
              fontSize: Tokens.textLG,
              color: Tokens.textPrimary,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.sp10,
              vertical: Tokens.sp4,
            ),
            decoration: BoxDecoration(
              color: Tokens.orangeChip,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count ${count == 1 ? "place".tr : "places".tr}",
              style: const TextStyle(
                fontSize: Tokens.textXS,
                color: Tokens.orangeChipText,
                fontFamily: AppThemeData.semiBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}
