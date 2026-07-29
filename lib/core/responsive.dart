import 'package:flutter/material.dart';

@immutable
final class Responsive {
  final double sw;
  final double sh;

  const Responsive({required this.sw, required this.sh});

  factory Responsive.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Responsive(sw: size.width, sh: size.height);
  }

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  // Layout
  double get hPad => isSmall ? 12 : (isLarge ? 16 : 12);

  double get cardWidth => isSmall ? 120 : (isLarge ? 155 : 136);

  double get cardImgH => isSmall ? 80 : (isLarge ? 108 : 92);

  double get prodScrollH => cardImgH + 120;

  // Typography
  double get nameFs => isSmall ? 11.5 : (isLarge ? 13.5 : 12.5);

  double get specPriceFs => isSmall ? 13 : (isLarge ? 15 : 14);

  double get origPriceFs => isSmall ? 8 : (isLarge ? 10 : 9);

  double get badgeFs => isSmall ? 7.5 : (isLarge ? 9 : 8);

  double get saveLblFs => isSmall ? 7 : (isLarge ? 8.5 : 7.5);

  double get qtyFs => isSmall ? 12 : (isLarge ? 14 : 13);

  double get closedFs => isSmall ? 10 : (isLarge ? 12 : 11);

  // Buttons
  double get btnH => isSmall ? 28 : (isLarge ? 34 : 30);

  double get btnRadius => isSmall ? 7 : (isLarge ? 10 : 8);

  double get btnIconSz => isSmall ? 13 : (isLarge ? 16 : 14);

  // Veg Dot
  double get vegOuter => isSmall ? 14 : (isLarge ? 17 : 15);

  double get vegInner => isSmall ? 8 : (isLarge ? 11 : 9.5);

  // Restaurant
  double get restNameFs => isSmall ? 13 : (isLarge ? 15 : 14);

  double get metaFs => isSmall ? 9 : (isLarge ? 11 : 10);

  @override
  bool operator ==(Object other) =>
      other is Responsive && other.sw == sw && other.sh == sh;

  @override
  int get hashCode => Object.hash(sw, sh);
}

abstract final class C {
  static const Color brand = Color(0xFFD12477);
  static const Color brandLight = Color(0xFFFCE8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF5F0FA);
  static const Color border = Color(0xFFEEE8F8);
  static const Color text1 = Color(0xFF13111A);
  static const Color text3 = Color(0xFF9B95A8);
  static const Color green = Color(0xFF1DB87A);
  static const Color red = Color(0xFFE84040);
  static const Color overlay = Color(0x55000000);
  static const Color closedPill = Color(0xCC000000);

  // Wallet badge
}
