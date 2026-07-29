import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';
import '../../provider/address_list_provider.dart';

class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isPrimary;
  final VoidCallback onTap;

  const QuickActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? AppThemeData.primary300 : Tokens.card;
    final labelColor = isPrimary ? Colors.white : Tokens.textPrimary;
    final subColor = isPrimary
        ? Colors.white.withOpacity(0.78)
        : Tokens.textMuted;
    final iconBg = isPrimary
        ? Colors.white.withOpacity(0.18)
        : Tokens.orangeChip;
    final iconColor = isPrimary ? Colors.white : AppThemeData.primary300;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.rLG),
        child: Ink(
          padding: const EdgeInsets.all(Tokens.sp14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Tokens.rLG),
            border: Border.all(
              color: isPrimary ? AppThemeData.primary300 : Tokens.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(Tokens.rSM),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: Tokens.sp12),
              Text(
                label,
                style: TextStyle(
                  fontSize: Tokens.textSM,
                  color: labelColor,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Tokens.sp4),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: Tokens.textXS,
                  color: subColor,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionRow extends StatelessWidget {
  final AddressListProvider ctrl;
  final VoidCallback onAddNew;
  final Future<void> Function() onUseMyLocation;

  const QuickActionRow({
    required this.ctrl,
    required this.onAddNew,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickActionTile(
            icon: Icons.my_location_rounded,
            label: "Use my location".tr,
            sublabel: "Auto-detect".tr,
            isPrimary: false,
            onTap: () => onUseMyLocation(),
          ),
        ),
        const SizedBox(width: Tokens.sp12),
        Expanded(
          child: QuickActionTile(
            icon: Icons.add_location_alt_rounded,
            label: "Add address".tr,
            sublabel: "Save a place".tr,
            isPrimary: true,
            onTap: onAddNew,
          ),
        ),
      ],
    );
  }
}
