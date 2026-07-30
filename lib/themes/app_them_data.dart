import 'package:flutter/material.dart';

class AppThemeData {
  static const Color primary50 = Color(0xFFFFEBE5);
  static const Color primary100 = Color(0xFFFFC0AB);
  static const Color primary200 = Color(0xFFFF9472);
  static Color primary300 = const Color(0xFFFF6839);
  static const Color primary400 = Color(0xFFB24826);
  static const Color primary500 = Color(0xFF662713);
  static const Color primary600 = Color(0xFF1A0600);

  static const Color primary1000 = Color(0xFFFF6B2C);
  static const Color primary2000 = Color(0xFFFFCBA8);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF030712);

  // Mart Home screen background color - reusable across all screens
  static const Color homeScreenBackground = Color(0xFFFAF9EE);

  static const Color info50 = Color(0xFFE5F9FF);
  static const Color info100 = Color(0xFFACECFF);
  static const Color info200 = Color(0xFF72DEFF);
  static const Color info300 = Color(0xFF38D0FF);
  static const Color info400 = Color(0xFF2692B2);
  static const Color info500 = Color(0xFF135366);
  static const Color info600 = Color(0xFF00141A);

  static const Color danger50 = Color(0xFFFFE5E6);
  static const Color danger100 = Color(0xFFFFACAE);
  static const Color danger200 = Color(0xFFFF7277);
  static const Color danger300 = Color(0xFFFF3840);
  static const Color danger400 = Color(0xFFB2262B);
  static const Color danger500 = Color(0xFF661316);
  static const Color danger600 = Color(0xFF1A0001);

  static const Color secondary50 = Color(0xFFEBE5FF);
  static const Color secondary100 = Color(0xFFC0ABFF);
  static const Color secondary200 = Color(0xFF9472FF);
  static const Color secondary300 = Color(0xFF6839FF);
  static const Color secondary400 = Color(0xFF4826B2);
  static const Color secondary500 = Color(0xFF271366);
  static const Color secondary600 = Color(0xFF06001A);

  static const Color success50 = Color(0xFFE5FFF5);
  static const Color success100 = Color(0xFFA1FFD9);
  static const Color success200 = Color(0xFF5DFFBE);
  static const Color success300 = Color(0xFF19FFA3);
  static const Color success400 = Color(0xFF10B271);
  static const Color success500 = Color(0xFF086640);
  static const Color success600 = Color(0xFF001A0F);
  static const Color lightGreen = Color(0XFFEFF9EB);
  static const Color darkGreen = Color(0XFF3F8826);

  static const Color warning50 = Color(0xFFFFF8E5);
  static const Color warning100 = Color(0xFFFFE9AB);
  static const Color warning200 = Color(0xFFFFDA72);
  static const Color warning300 = Color(0xFFFFCB39);
  static const Color warning400 = Color(0xFFB28D26);
  static const Color warning500 = Color(0xFF665013);
  static const Color warning600 = Color(0xFF191200);

  static const Color grey50 = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  static const Color outrageous300 = Color(0xFFFF6839);

  static const String black = 'Outfit-Black';
  static const String bold = 'Outfit-Bold';
  static const String extraBold = 'Outfit-ExtraBold';
  static const String extraLight = 'Outfit-ExtraLight';
  static const String light = 'Outfit-Light';
  static const String medium = 'Outfit-Medium';
  static const String regular = 'Outfit-Regular';
  static const String semiBold = 'Outfit-SemiBold';
  static const String thin = 'Outfit-Thin';
  static const String montserrat = 'Montserrat';
  static const String montserratRegular = 'Montserrat-Regular';

  static const String googleSansCode = 'GoogleSansCode';

  static const kGradEnd = Color(0xFFFF6B35);

  // Accent & surface palette
  static const kAccentAmber = Color(0xFFFFC107);
  static const kBgCanvas = Color(0xFFF7F7F8);
  static const kCardShadow = Color(0x14000000);
  static const kCardShadowMd = Color(0x1F000000);

  // Status colours
  static const kOpenGreen = Color(0xFF2ECC71);
  static const kClosedRed = Color(0xFFE74C3C);

  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeMid = Color(0xFFFFD4C2);
  static const Color green = Color(0xFF1DB954);
  static const Color greenLight = Color(0xFFE8FDF0);
  static const Color red = Color(0xFFEF4444);
  static const Color pageBg = Color(0xFFF8F6F3);
  static const Color textPrimary = Color(0xFF1A1208);
  static const Color textMuted = Color(0xFF8B8377);
  static const Color textLight = Color(0xFFC4BFB8);
  static const Color divider = Color(0xFFF0EDE8);
  static const Color chipBorder = Color(0xFFEEEBE6);

  static const String fontSemiBold = AppThemeData.semiBold;
  static const String fontMedium = AppThemeData.medium;
  static const String fontBold = AppThemeData.bold;

  static const kBrand = Color(0xFFFF3008);
  static const kBrandDeep = Color(0xFFCC1A00);
  static const kBrandLight = Color(0xFFFF6820);
  static const kGradEnds = Color(0xFFff5201);
}

class ZColors {
  static const kGradStart = Color(0xFFE8192C);
  static const kGradEnd = Color(0xFFFF6B35);
  static const Color primary = Color(0xFFE74C3C);
  static const Color primaryLight = Color(0xFFFFF0F1);
  static const Color primaryDark = Color(0xFFC0000F);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6D6D6D);
  static const Color textTertiary = Color(0xFFAAAAAA);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color iconBg = Color(0xFFFFF4F5);
  static const Color greenAccent = Color(0xFF26A541);
  static const Color amberAccent = Color(0xFFF5A623);
}

final kSectionGradient = const LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0x3833B5E5), // ~0.45 opacity
    Color(0x3833B5E5), // ~0.22
    Color(0x1A33B5E5), // ~0.10
    Color(0x0D33B5E5), // ~0.05
  ],
  stops: [0.0, 0.3, 0.7, 1.0],
);

class _T {}

class W {
  // Brand
  static const Color red = Color(0xFFE23744);

  // Coin gold
  static const Color gold = Color(0xFFFF9500);
  static const Color goldLight = Color(0xFFFFF8EC);
  static const Color goldDark = Color(0xFFD4780A);

  // Money green
  static const Color greenLight = Color(0xFFEEFBF1);

  // Neutrals
  static const Color bg = Color(0xFFF7F7F7);
  static const double radius = 20;
  static const double cardRadius = 16;
}
