import 'dart:ui';

class ColorConst {
  static Color white = Color(0xffFFFFFF);
  static Color martPrimary = Color(0xFF70892E);
  static Color orange200 = Color(0xFFFFCC80);
  static Color greenLight = Color(0xFF70892E);
  static Color orangeLight = Color(0xFFFFA400);
  static Color blackColor = Color(0xFF000000);

  // Primary gradient — warm food-app red→deep orange
  static const kGradStart = Color(0xFFE8192C);
  static const kGradEnd = Color(0xFFFF6B35);

  // Accent & surface palette
  static const kAccentAmber = Color(0xFFFFC107);
  static const kSurfaceWhite = Color(0xFFFFFFFF);
  static const kBgCanvas = Color(0xFFF7F7F8);
  static const kCardShadow = Color(0x14000000);
  static const kCardShadowMd = Color(0x1F000000);

  // Status colours
  static const kOpenGreen = Color(0xFF2ECC71);
  static const kClosedRed = Color(0xFFE74C3C);

  // Typography scale (used as named constants for clarity)
  static const kFontXS = 9.0;
  static const kFontSM = 11.0;
  static const kFontMD = 13.0;
  static const kFontLG = 15.0;
  static const kFontXL = 18.0;
  static const kFontXXL = 22.0;

  // Radius tokens
  static const kRadiusSM = 8.0;
  static const kRadiusMD = 14.0;
  static const kRadiusLG = 20.0;
  static const kRadiusXL = 28.0;

  /// How far the banner overlaps INTO the gradient.
  static const double kBannerPeekAbove = 80.0;
}
