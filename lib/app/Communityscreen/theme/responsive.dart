import 'package:flutter/material.dart';

/// Central breakpoints so every screen agrees on what counts as
/// "mobile", "tablet", and "desktop" — no magic numbers scattered
/// through individual widgets.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  /// Widest the main content column is allowed to get. Past this,
  /// extra space stays empty on the sides instead of stretching
  /// cards into unreadably long lines.
  static const double maxContentWidth = 900;
}

enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final w = screenWidth;
    if (w >= Breakpoints.desktop) return ScreenSize.desktop;
    if (w >= Breakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;

  bool get isTablet => screenSize == ScreenSize.tablet;

  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Horizontal page padding — tight on phones, roomier as the
  /// viewport grows so content doesn't hug the edges on tablet/desktop.
  double get pagePadding {
    switch (screenSize) {
      case ScreenSize.mobile:
        return 10;
      case ScreenSize.tablet:
        return 32;
      case ScreenSize.desktop:
        return 40;
    }
  }
}

/// Keeps the main content column readable on wide screens by capping
/// its width and centering it, instead of letting cards stretch to
/// fill an ultrawide monitor.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
