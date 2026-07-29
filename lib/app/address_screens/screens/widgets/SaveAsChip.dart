import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';
import 'AddressFormSheet.dart';

class SaveAsChip extends StatelessWidget {
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  const SaveAsChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  static String _iconPath(String type) => switch (type) {
    'Home' => "assets/icons/ic_home_add.svg",
    'Work' => "assets/icons/ic_work.svg",
    'Hotel' => "assets/icons/ic_building.svg",
    _ => "assets/icons/ic_location.svg",
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.sp14,
          vertical: Tokens.sp10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? kBrandGradient : null,
          color: isSelected ? null : Tokens.chipBg,
          borderRadius: BorderRadius.circular(Tokens.rMD),
          border: Border.all(
            color: isSelected ? Colors.transparent : Tokens.chipBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Tokens.gradStart.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              _iconPath(type),
              width: 17,
              height: 17,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : Tokens.mutedIcon,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: Tokens.sp8),
            Text(
              type.tr,
              style: TextStyle(
                fontSize: Tokens.textSM,
                color: isSelected ? Colors.white : Tokens.textSecondary,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
