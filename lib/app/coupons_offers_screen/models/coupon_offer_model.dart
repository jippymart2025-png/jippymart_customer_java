import 'dart:ui';

class CouponModel {
  final String amount;
  final String amountLabel;
  final String title;
  final String subtitle;
  final String code;
  final String badge;
  final String saveText;
  final CouponType type;

  const CouponModel({
    required this.amount,
    required this.amountLabel,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.badge,
    required this.saveText,
    required this.type,
  });
}

enum CouponType { green, orange, purple, blue }

class CouponColors {
  final Color primary;
  final Color background;
  final Color badgeBackground;

  const CouponColors({
    required this.primary,
    required this.background,
    required this.badgeBackground,
  });

  factory CouponColors.fromType(CouponType type) {
    switch (type) {
      case CouponType.green:
        return const CouponColors(
          primary: Color(0xFF258A4A),
          background: Color(0xFFEAF6ED),
          badgeBackground: Color(0xFFE8F5EA),
        );

      case CouponType.orange:
        return const CouponColors(
          primary: Color(0xFFE84B24),
          background: Color(0xFFFFF1EB),
          badgeBackground: Color(0xFFFFECE6),
        );

      case CouponType.purple:
        return const CouponColors(
          primary: Color(0xFF7138B5),
          background: Color(0xFFF4ECFC),
          badgeBackground: Color(0xFFF0E7FB),
        );

      case CouponType.blue:
        return const CouponColors(
          primary: Color(0xFF145BAA),
          background: Color(0xFFEDF5FF),
          badgeBackground: Color(0xFFE8F1FC),
        );
    }
  }
}
