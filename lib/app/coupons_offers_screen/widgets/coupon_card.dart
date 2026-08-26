// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../../Communityscreen/theme/app_theme.dart';
// import '../models/coupon_offer_model.dart';
//
// class CouponCard extends StatefulWidget {
//   final CouponModel coupon;
//   final VoidCallback onApply;
//
//   const CouponCard({super.key, required this.coupon, required this.onApply});
//
//   @override
//   State<CouponCard> createState() => _CouponCardState();
// }
//
// class _CouponCardState extends State<CouponCard> {
//   bool _pressed = false;
//   bool _copied = false;
//
//   CouponColors get colors => CouponColors.fromType(widget.coupon.type);
//
//   void _copyCode() async {
//     await Clipboard.setData(ClipboardData(text: widget.coupon.code));
//     if (!mounted) return;
//     setState(() => _copied = true);
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) setState(() => _copied = false);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedScale(
//       scale: _pressed ? 0.985 : 1,
//       duration: const Duration(milliseconds: 120),
//       curve: Curves.easeOut,
//       child: GestureDetector(
//         onTapDown: (_) => setState(() => _pressed = true),
//         onTapCancel: () => setState(() => _pressed = false),
//         onTapUp: (_) => setState(() => _pressed = false),
//         child: SizedBox(
//           height: 100,
//           child: ClipPath(
//             clipper: const _CouponCardClipper(),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: AppColors.surface,
//                 boxShadow: [
//                   BoxShadow(
//                     color: colors.primary.withOpacity(0.10),
//                     blurRadius: 18,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: CustomPaint(
//                 painter: _PerforationPainter(
//                   color: colors.primary.withOpacity(0.18),
//                 ),
//                 child: Row(
//                   children: [
//                     _AmountSection(colors: colors, coupon: widget.coupon),
//                     _DetailsSection(
//                       colors: colors,
//                       coupon: widget.coupon,
//                       copied: _copied,
//                       onCopy: _copyCode,
//                     ),
//                     _ActionSection(
//                       colors: colors,
//                       coupon: widget.coupon,
//                       onApply: widget.onApply,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _AmountSection extends StatelessWidget {
//   final CouponColors colors;
//   final CouponModel coupon;
//
//   const _AmountSection({required this.colors, required this.coupon});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 132,
//       margin: const EdgeInsets.fromLTRB(6, 6, 0, 6),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [colors.background, colors.background.withOpacity(0.55)],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.sell_rounded,
//             color: colors.primary.withOpacity(0.55),
//             size: 18,
//           ),
//           const SizedBox(height: 2),
//           Text(
//             coupon.amount,
//             style: TextStyle(
//               color: colors.primary,
//               fontSize: coupon.amount == 'FREE' ? 24 : 28,
//               fontWeight: FontWeight.w800,
//               height: 1,
//             ),
//           ),
//           const SizedBox(height: 1.5),
//           Text(
//             coupon.amountLabel,
//             style: TextStyle(
//               color: colors.primary.withOpacity(0.85),
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _DetailsSection extends StatelessWidget {
//   final CouponColors colors;
//   final CouponModel coupon;
//   final bool copied;
//   final VoidCallback onCopy;
//
//   const _DetailsSection({
//     required this.colors,
//     required this.coupon,
//     required this.copied,
//     required this.onCopy,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(7, 8, 5, 6),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
//               decoration: BoxDecoration(
//                 color: colors.badgeBackground,
//                 borderRadius: BorderRadius.circular(7),
//               ),
//               child: Text(
//                 coupon.badge,
//                 style: TextStyle(
//                   color: colors.primary,
//                   fontSize: 11.5,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.2,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               coupon.title,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.textPrimary,
//                 height: 1.15,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               coupon.subtitle,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 12.5,
//                 color: AppColors.textSecondary,
//                 fontWeight: FontWeight.w500,
//                 height: 1.3,
//               ),
//             ),
//             const Spacer(),
//             InkWell(
//               onTap: onCopy,
//               borderRadius: BorderRadius.circular(9),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: copied ? colors.background : AppColors.chipBackground,
//                   borderRadius: BorderRadius.circular(9),
//                   border: Border.all(
//                     color: copied
//                         ? colors.primary.withOpacity(0.4)
//                         : Colors.transparent,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       copied ? 'Copied' : coupon.code,
//                       style: TextStyle(
//                         fontSize: 6.5,
//                         fontWeight: FontWeight.w700,
//                         color: copied ? colors.primary : AppColors.textPrimary,
//                         letterSpacing: 0.3,
//                       ),
//                     ),
//                     const SizedBox(width: 7),
//                     Icon(
//                       copied ? Icons.check_rounded : Icons.copy_rounded,
//                       size: 15,
//                       color: copied ? colors.primary : AppColors.textSecondary,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _ActionSection extends StatelessWidget {
//   final CouponColors colors;
//   final CouponModel coupon;
//   final VoidCallback onApply;
//
//   const _ActionSection({
//     required this.colors,
//     required this.coupon,
//     required this.onApply,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 148,
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//       child: Column(
//         children: [
//           Text(
//             'You save',
//             style: TextStyle(
//               color: AppColors.textSecondary,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             coupon.saveText,
//             style: TextStyle(
//               color: colors.primary,
//               fontSize: 17,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const Spacer(),
//           SizedBox(
//             width: double.infinity,
//             height: 22,
//             child: ElevatedButton(
//               onPressed: onApply,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colors.primary,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shadowColor: Colors.transparent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(13),
//                 ),
//               ),
//               child: const Text(
//                 'Apply',
//                 style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
//               ),
//             ),
//           ),
//           // const SizedBox(height: 8),
//           // Row(
//           //   mainAxisAlignment: MainAxisAlignment.center,
//           //   children: const [
//           //     Text(
//           //       'View T&C',
//           //       style: TextStyle(
//           //         fontSize: 11.5,
//           //         color: AppColors.textMuted,
//           //         fontWeight: FontWeight.w600,
//           //       ),
//           //     ),
//           //     SizedBox(width: 2),
//           //     Icon(
//           //       Icons.info_outline_rounded,
//           //       size: 12,
//           //       color: AppColors.textMuted,
//           //     ),
//           //   ],
//           // ),
//         ],
//       ),
//     );
//   }
// }
//
// /// Paints a dashed perforation line where the ticket notches meet,
// /// so the split between the amount/details/action zones reads as a
// /// real ticket tear rather than a hard rule.
// class _PerforationPainter extends CustomPainter {
//   final Color color;
//
//   const _PerforationPainter({required this.color});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 1.4;
//     _dashedLine(canvas, size, 132, paint);
//     _dashedLine(canvas, size, size.width - 148, paint);
//   }
//
//   void _dashedLine(Canvas canvas, Size size, double x, Paint paint) {
//     const dashHeight = 5.0;
//     const dashGap = 4.0;
//     double y = 14;
//     while (y < size.height - 14) {
//       canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
//       y += dashHeight + dashGap;
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _PerforationPainter oldDelegate) =>
//       oldDelegate.color != color;
// }
//
// /// Draws the ticket-style card with circular perforation notches
// /// on the top/bottom edges, aligned with the amount and action
// /// section boundaries.
// class _CouponCardClipper extends CustomClipper<Path> {
//   const _CouponCardClipper();
//
//   static const double radius = 20.0;
//   static const double notchRadius = 8.0;
//
//   @override
//   Path getClip(Size size) {
//     final x1 = 132.0;
//     final x2 = size.width - 148.0;
//     return Path()
//       ..moveTo(radius, 0)
//       ..lineTo(x1 - notchRadius, 0)
//       ..arcToPoint(
//         Offset(x1 + notchRadius, 0),
//         radius: const Radius.circular(notchRadius),
//         clockwise: false,
//       )
//       ..lineTo(x2 - notchRadius, 0)
//       ..arcToPoint(
//         Offset(x2 + notchRadius, 0),
//         radius: const Radius.circular(notchRadius),
//         clockwise: false,
//       )
//       ..lineTo(size.width - radius, 0)
//       ..quadraticBezierTo(size.width, 0, size.width, radius)
//       ..lineTo(size.width, size.height - radius)
//       ..quadraticBezierTo(
//         size.width,
//         size.height,
//         size.width - radius,
//         size.height,
//       )
//       ..lineTo(x2 + notchRadius, size.height)
//       ..arcToPoint(
//         Offset(x2 - notchRadius, size.height),
//         radius: const Radius.circular(notchRadius),
//         clockwise: false,
//       )
//       ..lineTo(x1 + notchRadius, size.height)
//       ..arcToPoint(
//         Offset(x1 - notchRadius, size.height),
//         radius: const Radius.circular(notchRadius),
//         clockwise: false,
//       )
//       ..lineTo(radius, size.height)
//       ..quadraticBezierTo(0, size.height, 0, size.height - radius)
//       ..lineTo(0, radius)
//       ..quadraticBezierTo(0, 0, radius, 0)
//       ..close();
//   }
//
//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Communityscreen/theme/app_theme.dart';
import '../models/coupon_offer_model.dart';

/// Shared layout constants. The clipper and the perforation painter both
/// need to know exactly where the amount/action sections end, so we keep
/// a single source of truth here instead of duplicating magic numbers
/// (that mismatch was the root cause of earlier layout bugs).
const double _kAmountWidth = 90;
const double _kActionWidth = 90;

class CouponCard extends StatefulWidget {
  final CouponModel coupon;
  final VoidCallback onApply;

  const CouponCard({super.key, required this.coupon, required this.onApply});

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool _pressed = false;
  bool _copied = false;

  CouponColors get colors => CouponColors.fromType(widget.coupon.type);

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.coupon.code));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        // No hardcoded card height here on purpose: IntrinsicHeight below
        // measures the tallest section and sizes the card to fit it, so
        // the card can NEVER overflow regardless of text length/device.
        child: ClipPath(
          clipper: const _CouponCardClipper(),
          child: Container(
            constraints: const BoxConstraints(minWidth: 260),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _PerforationPainter(
                color: colors.primary.withOpacity(0.18),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AmountSection(colors: colors, coupon: widget.coupon),
                    _DetailsSection(
                      colors: colors,
                      coupon: widget.coupon,
                      copied: _copied,
                      onCopy: _copyCode,
                    ),
                    _ActionSection(
                      colors: colors,
                      coupon: widget.coupon,
                      onApply: widget.onApply,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  final CouponColors colors;
  final CouponModel coupon;

  const _AmountSection({required this.colors, required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kAmountWidth,
      margin: const EdgeInsets.fromLTRB(5, 5, 0, 5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.background, colors.background.withOpacity(0.55)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sell_rounded,
            color: colors.primary.withOpacity(0.55),
            size: 15,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              coupon.amount,
              maxLines: 1,
              style: TextStyle(
                color: colors.primary,
                fontSize: coupon.amount == 'FREE' ? 20 : 23,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            coupon.amountLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primary.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final CouponColors colors;
  final CouponModel coupon;
  final bool copied;
  final VoidCallback onCopy;

  const _DetailsSection({
    required this.colors,
    required this.coupon,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 5, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.badgeBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                coupon.badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              coupon.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              coupon.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(8),
                splashColor: colors.primary.withOpacity(0.12),
                highlightColor: colors.primary.withOpacity(0.08),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: copied
                        ? colors.background
                        : AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: copied
                          ? colors.primary.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                          child: Text(
                            copied ? 'Copied' : coupon.code,
                            key: ValueKey(copied),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: copied
                                  ? colors.primary
                                  : AppColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          copied ? Icons.check_rounded : Icons.copy_rounded,
                          key: ValueKey(copied),
                          size: 13,
                          color: copied
                              ? colors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final CouponColors colors;
  final CouponModel coupon;
  final VoidCallback onApply;

  const _ActionSection({
    required this.colors,
    required this.coupon,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kActionWidth,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You save',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              coupon.saveText,
              maxLines: 1,
              style: TextStyle(
                color: colors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onApply();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                animationDuration: const Duration(milliseconds: 120),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a dashed perforation line where the ticket notches meet,
/// so the split between the amount/details/action zones reads as a
/// real ticket tear rather than a hard rule.
class _PerforationPainter extends CustomPainter {
  final Color color;

  const _PerforationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    _dashedLine(canvas, size, _kAmountWidth, paint);
    _dashedLine(canvas, size, size.width - _kActionWidth, paint);
  }

  void _dashedLine(Canvas canvas, Size size, double x, Paint paint) {
    const dashHeight = 5.0;
    const dashGap = 4.0;
    double y = 10;
    while (y < size.height - 10) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Draws the ticket-style card with circular perforation notches
/// on the top/bottom edges, aligned with the amount and action
/// section boundaries. Uses the same _kAmountWidth/_kActionWidth
/// constants as the sections themselves so the notches can never
/// drift out of alignment with the actual layout.
class _CouponCardClipper extends CustomClipper<Path> {
  const _CouponCardClipper();

  static const double radius = 16.0;
  static const double notchRadius = 7.0;

  @override
  Path getClip(Size size) {
    final x1 = _kAmountWidth;
    final x2 = size.width - _kActionWidth;
    return Path()
      ..moveTo(radius, 0)
      ..lineTo(x1 - notchRadius, 0)
      ..arcToPoint(
        Offset(x1 + notchRadius, 0),
        radius: const Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(x2 - notchRadius, 0)
      ..arcToPoint(
        Offset(x2 + notchRadius, 0),
        radius: const Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(x2 + notchRadius, size.height)
      ..arcToPoint(
        Offset(x2 - notchRadius, size.height),
        radius: const Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(x1 + notchRadius, size.height)
      ..arcToPoint(
        Offset(x1 - notchRadius, size.height),
        radius: const Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
