import 'package:flutter/material.dart';

/// Single source of truth for every color used in the app.
/// Change a value here and it updates everywhere — no more hunting
/// through widgets for hard-coded hex codes.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2A66E8);
  static const Color primaryDark = Color(0xFF1A4FC4);
  static const Color primarySoft = Color(0xFFEAF0FE);

  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE9EDF3);

  static const Color textPrimary = Color(0xFF10202F);
  static const Color textSecondary = Color(0xFF5C7085);
  static const Color textMuted = Color(0xFF9AABBC);

  static const Color success = Color(0xFF1F9254);
  static const Color successSoft = Color(0xFFE4F6EA);
  static const Color warning = Color(0xFFF0A93B);
  static const Color error = Color(0xFFE5484D);

  // Category accent colors — one per cuisine/order type, kept in a
  // single palette so new categories stay visually consistent.
  static const Color accentOrange = Color(0xFFFF7A45);
  static const Color accentRed = Color(0xFFE5484D);
  static const Color accentGreen = Color(0xFF1F9254);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentYellow = Color(0xFFF0B429);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double pill = 999;
}

class AppText {
  AppText._();

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle link = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
}

/// Reusable elevation/shape so every card in the app looks intentional
/// instead of each widget inventing its own shadow values.
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({double radius = AppRadius.md}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration outlinedCard({double radius = AppRadius.md}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
    );
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'System',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
