import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';

class AddressTypeBadge extends StatelessWidget {
  final String? type;

  const AddressTypeBadge({this.type});

  @override
  Widget build(BuildContext context) {
    final normalized = type?.toLowerCase().trim() ?? '';

    final (IconData icon, Color bg, Color fg) = switch (normalized) {
      'home' => (
        Icons.home_rounded,
        Tokens.orangeChip,
        AppThemeData.primary300,
      ),
      'work' => (Icons.work_rounded, Tokens.infoBlueBg, Tokens.infoBlue),
      'hotel' => (
        Icons.apartment_rounded,
        Tokens.hotelTealBg,
        Tokens.hotelTeal,
      ),
      _ => (Icons.place_rounded, Tokens.chipBg, Tokens.mutedIcon),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tokens.rMD),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DefaultBadge
// ─────────────────────────────────────────────────────────────────────────────

class DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.sp8,
        vertical: Tokens.sp4,
      ),
      decoration: BoxDecoration(
        color: Tokens.openGreenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 11,
            color: Tokens.openGreen,
          ),
          const SizedBox(width: 4),
          Text(
            "Default".tr,
            style: const TextStyle(
              fontSize: Tokens.textXS,
              color: Tokens.openGreen,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MoreButton
// ─────────────────────────────────────────────────────────────────────────────

class MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Tokens.chipBg,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: Tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetaChip — small info pill under the address card
// ─────────────────────────────────────────────────────────────────────────────

class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? Tokens.openGreenBg : Tokens.chipBg;
    final fg = highlighted ? Tokens.openGreen : Tokens.mutedIcon;
    final textColor = highlighted ? Tokens.openGreen : Tokens.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.sp10,
        vertical: Tokens.sp6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: Tokens.sp6),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.textXS,
              color: textColor,
              fontFamily: AppThemeData.medium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
