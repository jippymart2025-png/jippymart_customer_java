import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class Tokens {
  // Gradient
  static const gradStart = Color(0xFFE8192C);
  static const gradMid = Color(0xFFFF4E1F);
  static const gradEnd = Color(0xFFFF6B35);

  // Surface
  static const canvas = Color(0xFFF7F7F8);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEEEEF2);
  static const selectedBorder = Color(0xFFFFBDAD);

  // Semantic
  static const openGreen = Color(0xFF2ECC71);
  static const openGreenBg = Color(0xFFE8F8F0);
  static const infoBlue = Color(0xFF3498DB);
  static const infoBlueBg = Color(0xFFEBF5FB);
  static const hotelTeal = Color(0xFF1ABC9C);
  static const hotelTealBg = Color(0xFFE8F8F5);
  static const mutedIcon = Color(0xFF9B9BAA);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF555570);
  static const textMuted = Color(0xFF888899);

  // Chips / badges
  static const chipBg = Color(0xFFF2F2F5);
  static const chipBorder = Color(0xFFE0E0E8);
  static const orangeChip = Color(0xFFFFF0EC);
  static const orangeChipText = Color(0xFFD84315);

  // Radius
  static const double rXS = 8;
  static const double rSM = 12;
  static const double rMD = 16;
  static const double rLG = 20;
  static const double rXL = 24;
  static const double rXXL = 32;

  // Elevation / shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> heroBannerShadow = [
    BoxShadow(
      color: gradStart.withOpacity(0.22),
      blurRadius: 28,
      spreadRadius: 0,
      offset: const Offset(0, 14),
    ),
  ];

  // Type scale
  static const double textXS = 11;
  static const double textSM = 13;
  static const double textMD = 15;
  static const double textLG = 17;
  static const double textXL = 20;
  static const double textXXL = 24;

  // Spacing
  static const double sp4 = 4;
  static const double sp6 = 6;
  static const double sp8 = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp14 = 14;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp28 = 28;
  static const double sp32 = 32;
}
