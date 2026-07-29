import 'package:flutter/material.dart';

class Responsive {
  static width(double size, BuildContext context) {
    return MediaQuery.of(context).size.width * (size / 100);
  }

  static height(double size, BuildContext context) {
    return MediaQuery.of(context).size.height * (size / 100);
  }

  // ✅ Enhanced responsive utilities for large screen devices (Android 16+)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 650;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 650 &&
        MediaQuery.of(context).size.width < 1100;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1100;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 650;
  }

  // ✅ Get optimal padding for different screen sizes
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // ✅ Get optimal font size for different screen sizes
  static double getFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // ✅ Get optimal button size for different screen sizes
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  // ✅ Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // ✅ Get optimal content width for large screens
  static double getContentWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth;
    } else if (isTablet(context)) {
      return screenWidth * 0.8;
    } else {
      return screenWidth * 0.6;
    }
  }

  // ✅ Check if device is iPad
  static bool isIPad(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // iPad detection: width >= 768 or height >= 1024 (in portrait)
    return size.shortestSide >= 600;
  }

  // ✅ Get optimal column count for grid layouts
  static int getGridColumnCount(BuildContext context, {int mobileColumns = 2}) {
    if (isIPad(context)) {
      return isLandscape(context) ? 4 : 3;
    } else if (isTablet(context)) {
      return isLandscape(context) ? 3 : 2;
    }
    return mobileColumns;
  }

  // ✅ Get optimal card width for iPad
  static double getCardWidth(BuildContext context, {double? maxWidth}) {
    if (isIPad(context)) {
      final contentWidth = getContentWidth(context);
      final cardWidth = contentWidth / getGridColumnCount(context);
      return maxWidth != null ? cardWidth.clamp(0, maxWidth) : cardWidth;
    }
    return double.infinity;
  }

  // ✅ Get optimal spacing for iPad
  static double getSpacing(BuildContext context, {double baseSpacing = 16.0}) {
    if (isIPad(context)) {
      return baseSpacing * 1.5;
    } else if (isTablet(context)) {
      return baseSpacing * 1.25;
    }
    return baseSpacing;
  }

  // ✅ Get optimal horizontal spacing (for padding)
  static double getHorizontalSpacing(
    BuildContext context, {
    double baseSpacing = 16.0,
  }) {
    return getSpacing(context, baseSpacing: baseSpacing);
  }

  // ✅ Get optimal max content width (prevents content from being too wide on iPad)
  static double getMaxContentWidth(BuildContext context) {
    if (isIPad(context)) {
      return 1200.0; // Max width for iPad
    } else if (isTablet(context)) {
      return 900.0; // Max width for tablets
    }
    return double.infinity; // No limit for mobile
  }
}

// Typography scale (used as named constants for clarity)
const kFontXS = 9.0;
const kFontSM = 11.0;
const kFontMD = 13.0;
const kFontLG = 15.0;
const kFontXL = 18.0;
const kFontXXL = 22.0;

// Radius tokens
const kRadiusSM = 8.0;
const kRadiusMD = 14.0;
const kRadiusLG = 20.0;
const kRadiusXL = 28.0;

/// How far the banner overlaps INTO the gradient.
const double kBannerPeekAbove = 80.0;

class RS {
  final double sw;
  final double sh;

  const RS({required this.sw, required this.sh});

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  // ── Grid ──────────────────────────────────────────────────────
  // FIXED: Always 2 columns for phones (< 600), 3 for tablets (>= 600)
  int get gridCols {
    if (sw >= 600) return 3; // tablets
    return 2; // ALL phones — 2 columns always
  }

  double get gridSpacing => isSmall ? 8.0 : 10.0;

  double get gridAspectRatio {
    if (sw >= 600) return 0.78; // tablets
    if (sw < 360) return 0.68; // small phones — extra tall
    return 0.68; // all normal phones (Android + iPhone)
  }

  // Padding
  double get hPad => isSmall ? 10.0 : (isLarge ? 16.0 : 12.0);

  double get itemPad => isSmall ? 6.0 : (isLarge ? 10.0 : 8.0);

  // Font sizes — slightly larger now that we have 2 cols
  double get categoryFontSize => isSmall ? 16.0 : (isLarge ? 20.0 : 18.0);

  double get labelFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get nameFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get priceFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get strikethroughFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);

  double get ratingFontSize => isSmall ? 11.0 : (isLarge ? 13.0 : 12.0);

  double get unavailableFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get btnFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get btnIconSize => isSmall ? 15.0 : (isLarge ? 19.0 : 17.0);

  double get qtyFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get ratingIconSize => isSmall ? 13.0 : (isLarge ? 17.0 : 15.0);

  // Spacing
  double get labelGap => isSmall ? 3.0 : 4.0;

  double get nameGap => isSmall ? 1.0 : 2.0;

  double get ratingGap => isSmall ? 2.0 : 3.0;

  double get unavailableTopPad => isSmall ? 1.0 : 2.0;

  // Button — taller now we have room
  double get btnHeight => isSmall ? 30.0 : (isLarge ? 36.0 : 32.0);

  double get btnRadius => isSmall ? 8.0 : 10.0;

  double get btnInnerPad => isSmall ? 6.0 : 8.0;

  double get qtyHPad => isSmall ? 10.0 : 14.0;

  // Favorite icon
  double get favIconPos => isSmall ? 6.0 : 8.0;

  // No-products
  double get emptyVPad => isSmall ? 40.0 : (isLarge ? 80.0 : 60.0);

  double get emptyHPad => isSmall ? 16.0 : (isLarge ? 24.0 : 20.0);

  double get emptyIconSize => isSmall ? 60.0 : (isLarge ? 100.0 : 80.0);

  double get emptyTitleSize => isSmall ? 16.0 : (isLarge ? 20.0 : 18.0);

  double get emptySubSize => isSmall ? 12.0 : (isLarge ? 16.0 : 14.0);

  double get emptyTitleGap => isSmall ? 16.0 : (isLarge ? 24.0 : 20.0);

  double get emptySubGap => isSmall ? 8.0 : (isLarge ? 12.0 : 10.0);
}
