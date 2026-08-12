// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class WelcomeOfferPopup extends StatelessWidget {
//   const WelcomeOfferPopup({super.key});
//
//   static Future<void> show() async {
//     await Get.bottomSheet(
//       const WelcomeOfferPopup(),
//       backgroundColor: Colors.transparent,
//       barrierColor: Colors.black.withOpacity(0.4),
//       enterBottomSheetDuration: const Duration(milliseconds: 350),
//       exitBottomSheetDuration: const Duration(milliseconds: 250),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.20),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.4),
//                   width: 1.2,
//                 ),
//               ),
//               child: Stack(
//                 children: [
//                   Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(height: 10),
//
//                       const Text(
//                         'FLAT 20% OFF',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.w900,
//                           color: Color(0xFF5B20D6),
//                           height: 1.1,
//                         ),
//                       ),
//
//                       const SizedBox(height: 3),
//
//                       Text(
//                         'on your first Order',
//                         style: TextStyle(
//                           fontSize: 12.5,
//                           color: const Color(0xFF17213D).withOpacity(0.8),
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Use Code:',
//                             style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: const Color(0xFF17213D).withOpacity(0.85),
//                             ),
//                           ),
//
//                           const SizedBox(width: 8),
//
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: BackdropFilter(
//                               filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 6,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(0.25),
//                                   border: Border.all(
//                                     color: const Color(
//                                       0xFF6A2BD9,
//                                     ).withOpacity(0.8),
//                                     width: 1.3,
//                                   ),
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: const Text(
//                                   'JIPPY20',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w800,
//                                     color: Color(0xFF5B20D6),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       SizedBox(
//                         width: double.infinity,
//                         height: 46,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Get.back();
//
//                             // TODO:
//                             // Navigate to appointment screen
//                             //
//                             // Get.to(() => const AppointmentScreen());
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF5B20D6),
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           child: const Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 'Order Now',
//                                 style: TextStyle(
//                                   fontSize: 15.5,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                               SizedBox(width: 10),
//                               Icon(Icons.arrow_forward_rounded, size: 19),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       Text(
//                         'Offer valid for 7 days',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: const Color(0xFF17213D).withOpacity(0.65),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   // Close button
//                   Positioned(
//                     top: 0,
//                     right: 0,
//                     child: ClipOval(
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
//                         child: Material(
//                           color: Colors.white.withOpacity(0.3),
//                           shape: const CircleBorder(),
//                           child: InkWell(
//                             customBorder: const CircleBorder(),
//                             onTap: () => Get.back(),
//                             child: SizedBox(
//                               width: 30,
//                               height: 30,
//                               child: Icon(
//                                 Icons.close_rounded,
//                                 size: 18,
//                                 color: const Color(0xFF17213D).withOpacity(0.7),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Builds a zigzag / coupon-style outline around a rectangle.
Path _buildZigzagPath(Size size, double toothSize) {
  final path = Path();
  final w = size.width;
  final h = size.height;

  int hCount = (w / toothSize).round();
  if (hCount % 2 != 0) hCount += 1;
  if (hCount < 2) hCount = 2;
  final hStep = w / hCount;

  int vCount = (h / toothSize).round();
  if (vCount % 2 != 0) vCount += 1;
  if (vCount < 2) vCount = 2;
  final vStep = h / vCount;

  path.moveTo(0, 0);

  // Top edge
  for (int i = 0; i < hCount; i++) {
    final x = (i + 1) * hStep;
    final y = (i % 2 == 0) ? toothSize / 2 : 0.0;
    path.lineTo(x, y);
  }

  // Right edge
  for (int i = 0; i < vCount; i++) {
    final y = (i + 1) * vStep;
    final x = (i % 2 == 0) ? w - toothSize / 2 : w;
    path.lineTo(x, y);
  }

  // Bottom edge
  for (int i = 0; i < hCount; i++) {
    final x = w - (i + 1) * hStep;
    final y = (i % 2 == 0) ? h - toothSize / 2 : h;
    path.lineTo(x, y);
  }

  // Left edge
  for (int i = 0; i < vCount; i++) {
    final y = h - (i + 1) * vStep;
    final x = (i % 2 == 0) ? toothSize / 2 : 0.0;
    path.lineTo(x, y);
  }

  path.close();
  return path;
}

class _ZigzagClipper extends CustomClipper<Path> {
  final double toothSize;

  const _ZigzagClipper({this.toothSize = 10});

  @override
  Path getClip(Size size) => _buildZigzagPath(size, toothSize);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ZigzagBorderPainter extends CustomPainter {
  final double toothSize;
  final Color color;
  final double strokeWidth;

  const _ZigzagBorderPainter({
    this.toothSize = 10,
    this.color = Colors.white,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildZigzagPath(size, toothSize);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WelcomeOfferPopup extends StatelessWidget {
  const WelcomeOfferPopup({super.key});

  static Future<void> show() async {
    await Get.bottomSheet(
      const WelcomeOfferPopup(),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      enterBottomSheetDuration: const Duration(milliseconds: 350),
      exitBottomSheetDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipPath(
          clipper: const _ZigzagClipper(toothSize: 10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.35)),
              child: Stack(
                children: [
                  // Zigzag border stroke, drawn to match the clip path
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ZigzagBorderPainter(
                        toothSize: 10,
                        color: Colors.white.withOpacity(0.55),
                        strokeWidth: 1.4,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      const Text(
                        'FLAT 20% OFF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5B20D6),
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'on your first Order',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: const Color(0xFF17213D).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Use Code:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17213D).withOpacity(0.85),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6A2BD9,
                                    ).withOpacity(0.8),
                                    width: 1.3,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'JIPPY20',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5B20D6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();

                            // TODO:
                            // Navigate to appointment screen
                            //
                            // Get.to(() => const AppointmentScreen());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B20D6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Order Now',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 19),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Offer valid for 7 days',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF17213D).withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),

                  // Close button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Material(
                          color: Colors.white.withOpacity(0.3),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Get.back(),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: const Color(0xFF17213D).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
