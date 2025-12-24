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
  static double getHorizontalSpacing(BuildContext context, {double baseSpacing = 16.0}) {
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
