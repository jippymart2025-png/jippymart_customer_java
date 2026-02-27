// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:provider/provider.dart';
// //
// // import 'package:jippymart_customer/constant/constant.dart';
// // import 'package:jippymart_customer/themes/app_them_data.dart';
// // import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
// //
// // /// Returns coin reward for a given streak day (bonus on 10/20/30, else daily amount).
// // int _coinsForStreakDay(int day) {
// //   final bonus = WalletProvider.streakBonusForDay(day);
// //   return bonus > 0 ? bonus : Constant.checkinCoinsPerDay;
// // }
// //
// // /// Whether this day is a streak bonus goal day (10, 20, 30).
// // bool _isStreakBonusDay(int day) {
// //   return day == 10 || day == 20 || day == 30;
// // }
// //
// // class CheckinSection extends StatelessWidget {
// //   const CheckinSection({super.key, required this.wp});
// //
// //   final WalletProvider wp;
// //
// //   static const int _visibleDays = 30;
// //   static const double _dayBoxWidth = 48;
// //   static const double _dayBoxHeight = 64;
// //   static const double _connectorHeight = 2;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<WalletProvider>(
// //       builder: (context, wp, _) {
// //         final streakDay = wp.streakDay;
// //         final checkedInToday = wp.checkedInToday;
// //         final nextBonus = WalletProvider.nextStreakBonusDay(streakDay);
// //         final bonusCoins = nextBonus != null
// //             ? WalletProvider.streakBonusForDay(nextBonus)
// //             : 0;
// //
// //         // Show a window of days; when streak is 0, show 1..6; else show streakDay-2 .. streakDay+3
// //         final startDay = streakDay > 0 ? (streakDay - 2).clamp(1, 99) : 1;
// //         final dayNumbers = List<int>.generate(
// //           _visibleDays,
// //           (i) => (startDay + i).clamp(1, 99),
// //         );
// //
// //         return Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
// //           decoration: BoxDecoration(
// //             color: AppThemeData.grey50,
// //             borderRadius: BorderRadius.circular(20),
// //             boxShadow: const [
// //               BoxShadow(
// //                 color: Color(0x0D000000),
// //                 blurRadius: 24,
// //                 offset: Offset(0, 4),
// //                 spreadRadius: 0,
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               // Header: green calendar + "X day streak"
// //               Row(
// //                 children: [
// //                   Container(
// //                     padding: const EdgeInsets.all(6),
// //                     decoration: BoxDecoration(
// //                       color: AppThemeData.success100,
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: Icon(
// //                       Icons.calendar_today_rounded,
// //                       color: AppThemeData.success500,
// //                       size: 22,
// //                     ),
// //                   ),
// //                   const SizedBox(width: 10),
// //                   Text(
// //                     '${streakDay > 0 ? streakDay : 0} day streak'.tr,
// //                     style: TextStyle(
// //                       fontFamily: AppThemeData.bold,
// //                       fontSize: 18,
// //                       color: AppThemeData.grey900,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 6),
// //               Text(
// //                 'Visit every day & earn up to ${Constant.checkinCoinsPerDay} coins'
// //                     .tr,
// //                 style: TextStyle(
// //                   fontFamily: AppThemeData.regular,
// //                   fontSize: 13,
// //                   color: AppThemeData.grey600,
// //                 ),
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 'Reach day 10, 20 & 30 for bonus coins!'.tr,
// //                 style: TextStyle(
// //                   fontFamily: AppThemeData.medium,
// //                   fontSize: 12,
// //                   color: AppThemeData.warning500,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //
// //               // Loading state
// //               if (wp.loadingCheckin)
// //                 const Padding(
// //                   padding: EdgeInsets.symmetric(vertical: 16),
// //                   child: Center(
// //                     child: SizedBox(
// //                       height: 28,
// //                       width: 28,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     ),
// //                   ),
// //                 )
// //               else ...[
// //                 // Day boxes with connector line
// //                 _buildDayRow(
// //                   context,
// //                   wp,
// //                   dayNumbers,
// //                   startDay,
// //                   streakDay,
// //                   checkedInToday,
// //                 ),
// //                 const SizedBox(height: 20),
// //                 // CTA button
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: Material(
// //                     color: AppThemeData.primary300,
// //                     borderRadius: BorderRadius.circular(14),
// //                     child: InkWell(
// //                       onTap: wp.checkedInToday
// //                           ? null
// //                           : () => _doCheckin(context),
// //                       borderRadius: BorderRadius.circular(14),
// //                       child: Padding(
// //                         padding: const EdgeInsets.symmetric(vertical: 14),
// //                         child: Center(
// //                           child: Text(
// //                             wp.checkedInToday
// //                                 ? "You're done for today!".tr
// //                                 : 'Earn more coins'.tr,
// //                             style: TextStyle(
// //                               fontFamily: AppThemeData.semiBold,
// //                               fontSize: 16,
// //                               color: AppThemeData.grey50,
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //               if (nextBonus != null &&
// //                   bonusCoins > 0 &&
// //                   !wp.loadingCheckin) ...[
// //                 const SizedBox(height: 10),
// //                 Text(
// //                   'Next bonus: $bonusCoins coins on day $nextBonus.'.tr,
// //                   style: TextStyle(
// //                     fontFamily: AppThemeData.medium,
// //                     fontSize: 12,
// //                     color: AppThemeData.primary300,
// //                   ),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildDayRow(
// //     BuildContext context,
// //     WalletProvider wp,
// //     List<int> dayNumbers,
// //     int startDay,
// //     int streakDay,
// //     bool checkedInToday,
// //   ) {
// //     final content = List<Widget>.generate(dayNumbers.length * 2 - 1, (index) {
// //       if (index.isOdd) {
// //         return Container(
// //           width: 10,
// //           height: _connectorHeight,
// //           color: AppThemeData.grey200,
// //         );
// //       }
// //       final i = index ~/ 2;
// //       final day = dayNumbers[i];
// //       final effectiveToday = streakDay > 0 ? streakDay : 1;
// //       final isCompleted =
// //           day < effectiveToday || (day == effectiveToday && checkedInToday);
// //       final isTodayPending = day == effectiveToday && !checkedInToday;
// //       final isFuture = day > effectiveToday;
// //       final coins = _coinsForStreakDay(day);
// //       final isBonusDay = _isStreakBonusDay(day);
// //       return _DayBox(
// //         dayNumber: day,
// //         coins: coins,
// //         isCompleted: isCompleted,
// //         isTodayPending: isTodayPending,
// //         isFuture: isFuture,
// //         isBonusDay: isBonusDay,
// //         boxWidth: _dayBoxWidth,
// //         boxHeight: _dayBoxHeight,
// //       );
// //     });
// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       padding: const EdgeInsets.symmetric(horizontal: 4),
// //       child: Row(mainAxisSize: MainAxisSize.min, children: content),
// //     );
// //   }
// //
// //   Future<void> _doCheckin(BuildContext context) async {
// //     final wp = context.read<WalletProvider>();
// //     final err = await wp.doCheckin();
// //     if (!context.mounted) return;
// //     if (err != null) {
// //       Get.snackbar('Check-in'.tr, err);
// //     } else {
// //       Get.snackbar(
// //         'Check-in'.tr,
// //         'You earned ${wp.checkinStatus?.coinsAwarded ?? Constant.checkinCoinsPerDay} coins!'
// //             .tr,
// //       );
// //     }
// //   }
// // }
// //
// // class _DayBox extends StatelessWidget {
// //   const _DayBox({
// //     required this.dayNumber,
// //     required this.coins,
// //     required this.isCompleted,
// //     required this.isTodayPending,
// //     required this.isFuture,
// //     required this.isBonusDay,
// //     required this.boxWidth,
// //     required this.boxHeight,
// //   });
// //
// //   final int dayNumber;
// //   final int coins;
// //   final bool isCompleted;
// //   final bool isTodayPending;
// //   final bool isFuture;
// //   final bool isBonusDay;
// //   final double boxWidth;
// //   final double boxHeight;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final useCompletedStyle = isCompleted;
// //     final usePendingStyle = isTodayPending || isFuture;
// //     final isGoalHighlight = isBonusDay && !useCompletedStyle;
// //
// //     return SizedBox(
// //       width: boxWidth,
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Container(
// //             width: boxWidth,
// //             height: boxWidth,
// //             decoration: BoxDecoration(
// //               color: useCompletedStyle
// //                   ? AppThemeData.success400
// //                   : (isGoalHighlight
// //                         ? AppThemeData.warning50
// //                         : AppThemeData.grey50),
// //               borderRadius: BorderRadius.circular(12),
// //               border: isGoalHighlight
// //                   ? Border.all(color: AppThemeData.warning400, width: 2)
// //                   : (usePendingStyle
// //                         ? Border.all(color: AppThemeData.primary200, width: 1.5)
// //                         : null),
// //               boxShadow: isGoalHighlight
// //                   ? [
// //                       BoxShadow(
// //                         color: AppThemeData.warning400.withOpacity(0.35),
// //                         blurRadius: 10,
// //                         offset: const Offset(0, 2),
// //                         spreadRadius: 0,
// //                       ),
// //                     ]
// //                   : (usePendingStyle
// //                         ? [
// //                             BoxShadow(
// //                               color: AppThemeData.primary200.withOpacity(0.2),
// //                               blurRadius: 8,
// //                               offset: const Offset(0, 2),
// //                             ),
// //                           ]
// //                         : null),
// //             ),
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 if (isGoalHighlight)
// //                   Container(
// //                     margin: const EdgeInsets.only(bottom: 2),
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 4,
// //                       vertical: 1,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: AppThemeData.warning400,
// //                       borderRadius: BorderRadius.circular(6),
// //                     ),
// //                     child: Text(
// //                       'Goal'.tr,
// //                       style: TextStyle(
// //                         fontFamily: AppThemeData.bold,
// //                         fontSize: 8,
// //                         color: Colors.black,
// //                       ),
// //                     ),
// //                   ),
// //                 if (useCompletedStyle)
// //                   Icon(Icons.check_rounded, color: Colors.black, size: 20)
// //                 else
// //                   Icon(
// //                     isGoalHighlight
// //                         ? Icons.emoji_events_rounded
// //                         : Icons.monetization_on_rounded,
// //                     color: isGoalHighlight
// //                         ? AppThemeData.warning500
// //                         : AppThemeData.primary300,
// //                     size: isGoalHighlight ? 20 : 18,
// //                   ),
// //                 const SizedBox(height: 2),
// //                 Text(
// //                   '+$coins',
// //                   style: TextStyle(
// //                     fontFamily: AppThemeData.semiBold,
// //                     fontSize: isGoalHighlight ? 10 : 11,
// //                     color: useCompletedStyle
// //                         ? Colors.white
// //                         : (isGoalHighlight
// //                               ? AppThemeData.warning600
// //                               : AppThemeData.primary300),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             'Day $dayNumber',
// //             style: TextStyle(
// //               fontFamily: AppThemeData.medium,
// //               fontSize: 10,
// //               color: isGoalHighlight
// //                   ? AppThemeData.warning600
// //                   : AppThemeData.grey600,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // //
// //
// // // import 'dart:math' as math;
// // // import 'package:flutter/material.dart';
// // // import 'package:get/get.dart';
// // // import 'package:provider/provider.dart';
// // //
// // // import 'package:jippymart_customer/constant/constant.dart';
// // // import 'package:jippymart_customer/themes/app_them_data.dart';
// // // import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
// // //
// // // // ─── Helpers ────────────────────────────────────────────────────────────────
// // //
// // // int _coinsForStreakDay(int day) {
// // //   final bonus = WalletProvider.streakBonusForDay(day);
// // //   return bonus > 0 ? bonus : Constant.checkinCoinsPerDay;
// // // }
// // //
// // // bool _isStreakBonusDay(int day) => day == 10 || day == 20 || day == 30;
// // //
// // // // ─── Main Section ────────────────────────────────────────────────────────────
// // //
// // // class CheckinSection extends StatelessWidget {
// // //   const CheckinSection({super.key, required this.wp});
// // //
// // //   final WalletProvider wp;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Consumer<WalletProvider>(
// // //       builder: (context, wp, _) {
// // //         final streakDay = wp.streakDay;
// // //         final checkedInToday = wp.checkedInToday;
// // //         final nextBonus = WalletProvider.nextStreakBonusDay(streakDay);
// // //         final bonusCoins = nextBonus != null
// // //             ? WalletProvider.streakBonusForDay(nextBonus)
// // //             : 0;
// // //
// // //         final startDay = streakDay > 0 ? (streakDay - 2).clamp(1, 99) : 1;
// // //         final dayNumbers = List<int>.generate(
// // //           30,
// // //           (i) => (startDay + i).clamp(1, 99),
// // //         );
// // //
// // //         return Container(
// // //           decoration: BoxDecoration(
// // //             borderRadius: BorderRadius.circular(24),
// // //             gradient: LinearGradient(
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //               colors: [Colors.white, Colors.white, Colors.white],
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: const Color(0xFF0F3460).withOpacity(0.5),
// // //                 blurRadius: 32,
// // //                 offset: const Offset(0, 8),
// // //               ),
// // //             ],
// // //           ),
// // //           child: ClipRRect(
// // //             borderRadius: BorderRadius.circular(24),
// // //             child: Stack(
// // //               children: [
// // //                 // Decorative background orbs
// // //                 Positioned(
// // //                   top: -30,
// // //                   right: -20,
// // //                   child: _Orb(
// // //                     size: 120,
// // //                     color: AppThemeData.primary300.withOpacity(0.12),
// // //                   ),
// // //                 ),
// // //                 Positioned(
// // //                   bottom: -40,
// // //                   left: -10,
// // //                   child: _Orb(
// // //                     size: 100,
// // //                     color: AppThemeData.warning400.withOpacity(0.08),
// // //                   ),
// // //                 ),
// // //                 // Content
// // //                 Padding(
// // //                   padding: const EdgeInsets.all(20),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       _Header(streakDay: streakDay),
// // //                       const SizedBox(height: 14),
// // //                       _SubInfo(nextBonus: nextBonus, bonusCoins: bonusCoins),
// // //                       const SizedBox(height: 20),
// // //                       if (wp.loadingCheckin)
// // //                         const _LoadingState()
// // //                       else ...[
// // //                         _DayRow(
// // //                           dayNumbers: dayNumbers,
// // //                           streakDay: streakDay,
// // //                           checkedInToday: checkedInToday,
// // //                         ),
// // //                         const SizedBox(height: 20),
// // //                         _CheckinButton(
// // //                           checkedInToday: checkedInToday,
// // //                           onTap: () => _doCheckin(context),
// // //                         ),
// // //                       ],
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Future<void> _doCheckin(BuildContext context) async {
// // //     final wp = context.read<WalletProvider>();
// // //     final err = await wp.doCheckin();
// // //     if (!context.mounted) return;
// // //     if (err != null) {
// // //       Get.snackbar('Check-in'.tr, err);
// // //     } else {
// // //       Get.snackbar(
// // //         'Check-in'.tr,
// // //         'You earned ${wp.checkinStatus?.coinsAwarded ?? Constant.checkinCoinsPerDay} coins!'
// // //             .tr,
// // //       );
// // //     }
// // //   }
// // // }
// // //
// // // // ─── Sub-widgets ─────────────────────────────────────────────────────────────
// // //
// // // class _Orb extends StatelessWidget {
// // //   const _Orb({required this.size, required this.color});
// // //
// // //   final double size;
// // //   final Color color;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: size,
// // //       height: size,
// // //       decoration: BoxDecoration(shape: BoxShape.circle, color: color),
// // //     );
// // //   }
// // // }
// // //
// // // class _Header extends StatelessWidget {
// // //   const _Header({required this.streakDay});
// // //
// // //   final int streakDay;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: [
// // //         // Flame / streak icon container
// // //         Container(
// // //           width: 46,
// // //           height: 46,
// // //           decoration: BoxDecoration(
// // //             gradient: LinearGradient(
// // //               colors: [AppThemeData.warning400, AppThemeData.warning500],
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //             ),
// // //             borderRadius: BorderRadius.circular(14),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: AppThemeData.warning400.withOpacity(0.45),
// // //                 blurRadius: 12,
// // //                 offset: const Offset(0, 4),
// // //               ),
// // //             ],
// // //           ),
// // //           child: const Icon(
// // //             Icons.local_fire_department_rounded,
// // //             color: Colors.white,
// // //             size: 26,
// // //           ),
// // //         ),
// // //         const SizedBox(width: 14),
// // //         Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Text(
// // //               'Daily Streak',
// // //               style: TextStyle(
// // //                 fontFamily: AppThemeData.medium,
// // //                 fontSize: 12,
// // //                 color: Colors.black.withOpacity(0.55),
// // //                 letterSpacing: 0.8,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 2),
// // //             Row(
// // //               crossAxisAlignment: CrossAxisAlignment.end,
// // //               children: [
// // //                 Text(
// // //                   '${streakDay > 0 ? streakDay : 0}',
// // //                   style: TextStyle(
// // //                     fontFamily: AppThemeData.bold,
// // //                     fontSize: 28,
// // //                     color: Colors.black,
// // //                     height: 1,
// // //                   ),
// // //                 ),
// // //                 Padding(
// // //                   padding: const EdgeInsets.only(bottom: 3, left: 4),
// // //                   child: Text(
// // //                     'days'.tr,
// // //                     style: TextStyle(
// // //                       fontFamily: AppThemeData.medium,
// // //                       fontSize: 14,
// // //                       color: Colors.black.withOpacity(0.7),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //         const Spacer(),
// // //         // Coin balance pill
// // //         Container(
// // //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //           decoration: BoxDecoration(
// // //             color: Colors.black.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(20),
// // //             border: Border.all(color: Colors.white.withOpacity(0.15)),
// // //           ),
// // //           child: Row(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Icon(
// // //                 Icons.monetization_on_rounded,
// // //                 color: AppThemeData.warning400,
// // //                 size: 16,
// // //               ),
// // //               const SizedBox(width: 5),
// // //               Text(
// // //                 '+${Constant.checkinCoinsPerDay}/day'.tr,
// // //                 style: TextStyle(
// // //                   fontFamily: AppThemeData.semiBold,
// // //                   fontSize: 12,
// // //                   color: Colors.black.withOpacity(0.9),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }
// // //
// // // class _SubInfo extends StatelessWidget {
// // //   const _SubInfo({required this.nextBonus, required this.bonusCoins});
// // //
// // //   final int? nextBonus;
// // //   final int bonusCoins;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // //       decoration: BoxDecoration(
// // //         color: Colors.black.withOpacity(0.06),
// // //         borderRadius: BorderRadius.circular(14),
// // //         border: Border.all(color: Colors.black.withOpacity(0.08)),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Icon(
// // //             Icons.emoji_events_rounded,
// // //             color: AppThemeData.warning400,
// // //             size: 18,
// // //           ),
// // //           const SizedBox(width: 8),
// // //           Expanded(
// // //             child: Text(
// // //               nextBonus != null && bonusCoins > 0
// // //                   ? 'Reach day $nextBonus for $bonusCoins bonus coins!'.tr
// // //                   : 'Reach day 10, 20 & 30 for mega bonus coins!'.tr,
// // //               style: TextStyle(
// // //                 fontFamily: AppThemeData.medium,
// // //                 fontSize: 12,
// // //                 color: Colors.black.withOpacity(0.8),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _LoadingState extends StatelessWidget {
// // //   const _LoadingState();
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return const Padding(
// // //       padding: EdgeInsets.symmetric(vertical: 24),
// // //       child: Center(
// // //         child: SizedBox(
// // //           height: 28,
// // //           width: 28,
// // //           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _DayRow extends StatelessWidget {
// // //   const _DayRow({
// // //     required this.dayNumbers,
// // //     required this.streakDay,
// // //     required this.checkedInToday,
// // //   });
// // //
// // //   final List<int> dayNumbers;
// // //   final int streakDay;
// // //   final bool checkedInToday;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final effectiveToday = streakDay > 0 ? streakDay : 1;
// // //
// // //     return SingleChildScrollView(
// // //       scrollDirection: Axis.horizontal,
// // //       physics: const BouncingScrollPhysics(),
// // //       padding: const EdgeInsets.symmetric(horizontal: 2),
// // //       child: Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: List.generate(dayNumbers.length * 2 - 1, (index) {
// // //           if (index.isOdd) {
// // //             // Connector
// // //             final i = index ~/ 2;
// // //             final day = dayNumbers[i];
// // //             final isCompleted =
// // //                 day < effectiveToday ||
// // //                 (day == effectiveToday && checkedInToday);
// // //             return _Connector(isCompleted: isCompleted);
// // //           }
// // //
// // //           final i = index ~/ 2;
// // //           final day = dayNumbers[i];
// // //           final isCompleted =
// // //               day < effectiveToday || (day == effectiveToday && checkedInToday);
// // //           final isTodayPending = day == effectiveToday && !checkedInToday;
// // //           final isFuture = day > effectiveToday;
// // //           final isBonusDay = _isStreakBonusDay(day);
// // //
// // //           return _DayBox(
// // //             dayNumber: day,
// // //             coins: _coinsForStreakDay(day),
// // //             isCompleted: isCompleted,
// // //             isTodayPending: isTodayPending,
// // //             isFuture: isFuture,
// // //             isBonusDay: isBonusDay,
// // //           );
// // //         }),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _Connector extends StatelessWidget {
// // //   const _Connector({required this.isCompleted});
// // //
// // //   final bool isCompleted;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: 8,
// // //       height: 2,
// // //       decoration: BoxDecoration(
// // //         color: isCompleted
// // //             ? AppThemeData.success400.withOpacity(0.8)
// // //             : Colors.black.withOpacity(0.12),
// // //         borderRadius: BorderRadius.circular(1),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _CheckinButton extends StatelessWidget {
// // //   const _CheckinButton({required this.checkedInToday, required this.onTap});
// // //
// // //   final bool checkedInToday;
// // //   final VoidCallback onTap;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return SizedBox(
// // //       width: double.infinity,
// // //       child: AnimatedContainer(
// // //         duration: const Duration(milliseconds: 300),
// // //         decoration: BoxDecoration(
// // //           gradient: checkedInToday
// // //               ? LinearGradient(
// // //                   colors: [
// // //                     Colors.black.withOpacity(0.08),
// // //                     Colors.black.withOpacity(0.05),
// // //                   ],
// // //                 )
// // //               : LinearGradient(
// // //                   colors: [
// // //                     AppThemeData.primary300,
// // //                     AppThemeData.primary300.withBlue(
// // //                       math.min(255, AppThemeData.primary300.blue + 40),
// // //                     ),
// // //                   ],
// // //                   begin: Alignment.topLeft,
// // //                   end: Alignment.bottomRight,
// // //                 ),
// // //           borderRadius: BorderRadius.circular(16),
// // //           border: checkedInToday
// // //               ? Border.all(color: Colors.black.withOpacity(0.15))
// // //               : null,
// // //           boxShadow: checkedInToday
// // //               ? null
// // //               : [
// // //                   BoxShadow(
// // //                     color: AppThemeData.primary300.withOpacity(0.4),
// // //                     blurRadius: 16,
// // //                     offset: const Offset(0, 6),
// // //                   ),
// // //                 ],
// // //         ),
// // //         child: Material(
// // //           color: Colors.transparent,
// // //           child: InkWell(
// // //             onTap: checkedInToday ? null : onTap,
// // //             borderRadius: BorderRadius.circular(16),
// // //             child: Padding(
// // //               padding: const EdgeInsets.symmetric(vertical: 15),
// // //               child: Row(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Icon(
// // //                     checkedInToday
// // //                         ? Icons.check_circle_rounded
// // //                         : Icons.bolt_rounded,
// // //                     color: checkedInToday
// // //                         ? Colors.black.withOpacity(0.5)
// // //                         : Colors.black,
// // //                     size: 20,
// // //                   ),
// // //                   const SizedBox(width: 8),
// // //                   Text(
// // //                     checkedInToday
// // //                         ? "Come back tomorrow!".tr
// // //                         : 'Check in & earn coins'.tr,
// // //                     style: TextStyle(
// // //                       fontFamily: AppThemeData.semiBold,
// // //                       fontSize: 15,
// // //                       color: checkedInToday
// // //                           ? Colors.black.withOpacity(0.5)
// // //                           : Colors.black,
// // //                       letterSpacing: 0.3,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // // ─── Day Box ─────────────────────────────────────────────────────────────────
// // //
// // // class _DayBox extends StatelessWidget {
// // //   const _DayBox({
// // //     required this.dayNumber,
// // //     required this.coins,
// // //     required this.isCompleted,
// // //     required this.isTodayPending,
// // //     required this.isFuture,
// // //     required this.isBonusDay,
// // //   });
// // //
// // //   final int dayNumber;
// // //   final int coins;
// // //   final bool isCompleted;
// // //   final bool isTodayPending;
// // //   final bool isFuture;
// // //   final bool isBonusDay;
// // //
// // //   static const double _size = 52.0;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isGoalHighlight = isBonusDay && !isCompleted;
// // //
// // //     // Box gradient/color
// // //     Gradient? boxGradient;
// // //     Color? boxColor;
// // //     Border? boxBorder;
// // //     List<BoxShadow>? boxShadow;
// // //
// // //     if (isCompleted) {
// // //       boxGradient = LinearGradient(
// // //         colors: [AppThemeData.success400, AppThemeData.success500],
// // //         begin: Alignment.topLeft,
// // //         end: Alignment.bottomRight,
// // //       );
// // //       boxShadow = [
// // //         BoxShadow(
// // //           color: AppThemeData.success400.withOpacity(0.4),
// // //           blurRadius: 8,
// // //           offset: const Offset(0, 3),
// // //         ),
// // //       ];
// // //     } else if (isGoalHighlight) {
// // //       boxGradient = LinearGradient(
// // //         colors: [
// // //           AppThemeData.warning400.withOpacity(0.2),
// // //           AppThemeData.warning500.withOpacity(0.1),
// // //         ],
// // //         begin: Alignment.topLeft,
// // //         end: Alignment.bottomRight,
// // //       );
// // //       boxBorder = Border.all(color: AppThemeData.warning400, width: 1.5);
// // //       boxShadow = [
// // //         BoxShadow(
// // //           color: AppThemeData.warning400.withOpacity(0.3),
// // //           blurRadius: 10,
// // //           offset: const Offset(0, 3),
// // //         ),
// // //       ];
// // //     } else if (isTodayPending) {
// // //       boxGradient = LinearGradient(
// // //         colors: [
// // //           AppThemeData.primary300.withOpacity(0.25),
// // //           AppThemeData.primary300.withOpacity(0.1),
// // //         ],
// // //         begin: Alignment.topLeft,
// // //         end: Alignment.bottomRight,
// // //       );
// // //       boxBorder = Border.all(color: AppThemeData.primary300, width: 1.5);
// // //       boxShadow = [
// // //         BoxShadow(
// // //           color: AppThemeData.primary300.withOpacity(0.3),
// // //           blurRadius: 10,
// // //           offset: const Offset(0, 3),
// // //         ),
// // //       ];
// // //     } else {
// // //       // Future
// // //       boxColor = Colors.black.withOpacity(0.06);
// // //       boxBorder = Border.all(color: Colors.black.withOpacity(0.1));
// // //     }
// // //
// // //     return SizedBox(
// // //       width: _size,
// // //       child: Column(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           // Bonus day label above
// // //           SizedBox(
// // //             height: 16,
// // //             child: isGoalHighlight
// // //                 ? Container(
// // //                     padding: const EdgeInsets.symmetric(
// // //                       horizontal: 5,
// // //                       vertical: 2,
// // //                     ),
// // //                     decoration: BoxDecoration(
// // //                       color: AppThemeData.warning400,
// // //                       borderRadius: BorderRadius.circular(6),
// // //                     ),
// // //                     child: Text(
// // //                       '🏆 Bonus',
// // //                       style: const TextStyle(
// // //                         fontSize: 8,
// // //                         color: Colors.black,
// // //                         fontWeight: FontWeight.bold,
// // //                         height: 1,
// // //                       ),
// // //                     ),
// // //                   )
// // //                 : null,
// // //           ),
// // //           const SizedBox(height: 3),
// // //           Container(
// // //             width: _size,
// // //             height: _size,
// // //             decoration: BoxDecoration(
// // //               color: boxColor,
// // //               gradient: boxGradient,
// // //               border: boxBorder,
// // //               borderRadius: BorderRadius.circular(14),
// // //               boxShadow: boxShadow,
// // //             ),
// // //             child: Column(
// // //               mainAxisAlignment: MainAxisAlignment.center,
// // //               children: [
// // //                 if (isCompleted)
// // //                   const Icon(Icons.check_rounded, color: Colors.black, size: 22)
// // //                 else
// // //                   Icon(
// // //                     isGoalHighlight
// // //                         ? Icons.emoji_events_rounded
// // //                         : isTodayPending
// // //                         ? Icons.bolt_rounded
// // //                         : Icons.monetization_on_rounded,
// // //                     color: isGoalHighlight
// // //                         ? AppThemeData.warning400
// // //                         : isTodayPending
// // //                         ? AppThemeData.primary300
// // //                         : Colors.black.withOpacity(0.3),
// // //                     size: isGoalHighlight ? 20 : 18,
// // //                   ),
// // //                 const SizedBox(height: 3),
// // //                 Text(
// // //                   '+$coins',
// // //                   style: TextStyle(
// // //                     fontWeight: FontWeight.w700,
// // //                     fontSize: isGoalHighlight ? 10 : 11,
// // //                     color: isCompleted
// // //                         ? Colors.black
// // //                         : isGoalHighlight
// // //                         ? AppThemeData.warning400
// // //                         : isTodayPending
// // //                         ? AppThemeData.primary300
// // //                         : Colors.black.withOpacity(0.3),
// // //                     height: 1,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           const SizedBox(height: 5),
// // //           Text(
// // //             'Day $dayNumber',
// // //             style: TextStyle(
// // //               fontFamily: AppThemeData.medium,
// // //               fontSize: 9,
// // //               color: isCompleted
// // //                   ? AppThemeData.success400
// // //                   : isGoalHighlight
// // //                   ? AppThemeData.warning400
// // //                   : isTodayPending
// // //                   ? AppThemeData.primary300
// // //                   : Colors.black.withOpacity(0.35),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
//
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';

/// Returns coin reward for a given streak day (bonus on 10/20/30, else daily amount).
int _coinsForStreakDay(int day) {
  final bonus = WalletProvider.streakBonusForDay(day);
  return bonus > 0 ? bonus : Constant.checkinCoinsPerDay;
}

/// Whether this day is a streak bonus goal day (10, 20, 30).
bool _isStreakBonusDay(int day) => day == 10 || day == 20 || day == 30;

class CheckinSection extends StatelessWidget {
  const CheckinSection({
    super.key,
    required this.wp,
    required this.onCheckin,
  });

  final WalletProvider wp;
  final VoidCallback onCheckin;

  static const int _visibleDays = 30;
  static const double _dayBoxWidth = 52;
  static const double _dayBoxHeight = 68;

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wp, _) {
        // ── Streak logic ──────────────────────────────────────────────────────
        // streakDay reflects the CURRENT streak regardless of today's check-in.
        // If the user missed yesterday, WalletProvider should have already reset
        // streakDay to 0 before this widget is rendered.
        final streakDay = wp.streakDay; // 0 if missed, N if active
        final checkedInToday = wp.checkedInToday;

        // The displayed streak counter shows the streak BEFORE check-in too.
        // e.g. if streakDay == 5 and not yet checked in today, we still show 5.
        final displayStreak = streakDay;

        final nextBonus = WalletProvider.nextStreakBonusDay(streakDay);
        final bonusCoins = nextBonus != null
            ? WalletProvider.streakBonusForDay(nextBonus)
            : 0;

        // Day window: show from max(1, streakDay-1) so current day is near left
        final startDay = streakDay > 1 ? (streakDay - 1).clamp(1, 99) : 1;
        final dayNumbers = List<int>.generate(
          _visibleDays,
          (i) => (startDay + i).clamp(1, 99),
        );

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A1F2E), const Color(0xFF0F1420)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top header strip ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flame + streak count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _FlameIcon(active: displayStreak > 0),
                              const SizedBox(width: 8),
                              Text(
                                '$displayStreak',
                                style: const TextStyle(
                                  fontFamily: 'bold',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'day streak',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.55),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayStreak == 0
                                ? 'Start your streak today!'
                                : checkedInToday
                                ? 'Great job — come back tomorrow!'
                                : 'Check in to keep your streak alive!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coins badge
                    _CoinsBadge(coins: Constant.checkinCoinsPerDay),
                  ],
                ),
              ),

              // ── Milestone hint ────────────────────────────────────────────
              if (nextBonus != null && bonusCoins > 0) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MilestoneBanner(
                    daysLeft: nextBonus - streakDay,
                    targetDay: nextBonus,
                    bonusCoins: bonusCoins,
                    checkedInToday: checkedInToday,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Day scroll row ────────────────────────────────────────────
              if (wp.loadingCheckin)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                )
              else
                _buildDayRow(
                  context,
                  wp,
                  dayNumbers,
                  streakDay,
                  checkedInToday,
                ),

              const SizedBox(height: 16),

              // ── CTA ───────────────────────────────────────────────────────
              if (!wp.loadingCheckin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _CheckinButton(
                    checkedInToday: checkedInToday,
                    onTap: onCheckin,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    WalletProvider wp,
    List<int> dayNumbers,
    int streakDay,
    bool checkedInToday,
  ) {
    // effectiveToday: the day number the user is currently on
    // If streak is 0, they are on day 1 (first day)
    final effectiveToday = streakDay > 0 ? streakDay : 1;

    final items = <Widget>[];
    for (int i = 0; i < dayNumbers.length; i++) {
      final day = dayNumbers[i];

      // A day is "completed" if it's before today's day,
      // OR it's today AND the user has already checked in.
      final isCompleted =
          day < effectiveToday || (day == effectiveToday && checkedInToday);

      // Today pending = today's day and not yet checked in
      final isTodayPending = day == effectiveToday && !checkedInToday;
      final isFuture = day > effectiveToday;
      final coins = _coinsForStreakDay(day);
      final isBonusDay = _isStreakBonusDay(day);

      if (i > 0) {
        // Connector
        items.add(
          SizedBox(
            width: 8,
            child: Center(
              child: Container(
                height: 2,
                color: isCompleted
                    ? const Color(0xFF6C63FF).withOpacity(0.6)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        );
      }

      items.add(
        _DayBox(
          dayNumber: day,
          coins: coins,
          isCompleted: isCompleted,
          isTodayPending: isTodayPending,
          isFuture: isFuture,
          isBonusDay: isBonusDay,
          boxWidth: _dayBoxWidth,
          boxHeight: _dayBoxHeight,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FlameIcon extends StatelessWidget {
  const _FlameIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFFD93D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        size: 22,
      ),
    );
  }
}

class _CoinsBadge extends StatelessWidget {
  const _CoinsBadge({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD93D).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD93D).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFD93D),
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            '+$coins/day',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD93D),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneBanner extends StatelessWidget {
  const _MilestoneBanner({
    required this.daysLeft,
    required this.targetDay,
    required this.bonusCoins,
    required this.checkedInToday,
  });

  final int daysLeft;
  final int targetDay;
  final int bonusCoins;
  final bool checkedInToday;

  @override
  Widget build(BuildContext context) {
    // When already checked in today, daysLeft decreases by 1 more
    final effectiveDaysLeft = checkedInToday ? daysLeft : daysLeft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF9500).withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFF9500),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              effectiveDaysLeft <= 0
                  ? 'Claim your $bonusCoins coin bonus on day $targetDay!'
                  : '$effectiveDaysLeft day${effectiveDaysLeft == 1 ? '' : 's'} until $bonusCoins bonus coins on day $targetDay',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF9500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinButton extends StatelessWidget {
  const _CheckinButton({required this.checkedInToday, required this.onTap});

  final bool checkedInToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: checkedInToday ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: checkedInToday
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: checkedInToday ? Colors.white.withOpacity(0.07) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: checkedInToday
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              checkedInToday
                  ? Icons.check_circle_outline_rounded
                  : Icons.bolt_rounded,
              color: checkedInToday
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              checkedInToday
                  ? "You're done for today!"
                  : 'Check in & earn coins',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: checkedInToday
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day Box ───────────────────────────────────────────────────────────────────

class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.dayNumber,
    required this.coins,
    required this.isCompleted,
    required this.isTodayPending,
    required this.isFuture,
    required this.isBonusDay,
    required this.boxWidth,
    required this.boxHeight,
  });

  final int dayNumber;
  final int coins;
  final bool isCompleted;
  final bool isTodayPending;
  final bool isFuture;
  final bool isBonusDay;
  final double boxWidth;
  final double boxHeight;

  @override
  Widget build(BuildContext context) {
    // Style decision matrix
    // completed  → purple fill
    // todayPending → glowing purple border (active/pending)
    // bonusDay (not completed) → gold accent
    // future → subtle ghost

    final isActive = isTodayPending; // highlighted today, not yet checked in

    Color boxBg;
    Gradient? boxGradient;
    Border? boxBorder;
    List<BoxShadow>? shadows;
    Color iconColor;
    Color textColor;
    IconData icon;

    if (isCompleted) {
      boxGradient = const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      boxBg = Colors.transparent;
      boxBorder = null;
      shadows = [
        BoxShadow(
          color: const Color(0xFF6C63FF).withOpacity(0.35),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
      iconColor = Colors.white;
      textColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isBonusDay) {
      boxBg = const Color(0xFFFF9500).withOpacity(0.12);
      boxBorder = Border.all(color: const Color(0xFFFF9500), width: 1.5);
      shadows = [
        BoxShadow(
          color: const Color(0xFFFF9500).withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];
      iconColor = const Color(0xFFFF9500);
      textColor = const Color(0xFFFF9500);
      icon = Icons.emoji_events_rounded;
    } else if (isActive) {
      // Today, not yet checked in — pulsing purple ring
      boxBg = const Color(0xFF6C63FF).withOpacity(0.12);
      boxBorder = Border.all(color: const Color(0xFF6C63FF), width: 2);
      shadows = [
        BoxShadow(
          color: const Color(0xFF6C63FF).withOpacity(0.4),
          blurRadius: 14,
          offset: const Offset(0, 3),
          spreadRadius: 1,
        ),
      ];
      iconColor = const Color(0xFF9C88FF);
      textColor = const Color(0xFF9C88FF);
      icon = Icons.monetization_on_rounded;
    } else {
      // Future days
      boxBg = Colors.white.withOpacity(0.05);
      boxBorder = Border.all(color: Colors.white.withOpacity(0.08), width: 1);
      shadows = null;
      iconColor = Colors.white.withOpacity(0.2);
      textColor = Colors.white.withOpacity(0.2);
      icon = Icons.monetization_on_rounded;
    }

    return SizedBox(
      width: boxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day label on top for bonus days
          if (isBonusDay && !isCompleted)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'GOAL',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const SizedBox(height: 12), // keep alignment

          Container(
            width: boxWidth,
            height: boxWidth,
            decoration: BoxDecoration(
              gradient: boxGradient,
              color: boxBg,
              borderRadius: BorderRadius.circular(14),
              border: boxBorder,
              boxShadow: shadows,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: isBonusDay ? 20 : 18),
                const SizedBox(height: 2),
                Text(
                  '+$coins',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isActive ? '▶ Day $dayNumber' : 'Day $dayNumber',
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF9C88FF)
                  : isBonusDay && !isCompleted
                  ? const Color(0xFFFF9500)
                  : Colors.white.withOpacity(isCompleted ? 0.7 : 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
//
// /// Returns coin reward for a given streak day (bonus on 10/20/30, else daily amount).
// int _coinsForStreakDay(int day) {
//   final bonus = WalletProvider.streakBonusForDay(day);
//   return bonus > 0 ? bonus : Constant.checkinCoinsPerDay;
// }
//
// /// Whether this day is a streak bonus goal day (10, 20, 30).
// bool _isStreakBonusDay(int day) => day == 10 || day == 20 || day == 30;
//
// // ── Light theme color palette ─────────────────────────────────────────────────
// const _kPrimary = Color(0xFF6C63FF);
// const _kPrimaryLight = Color(0xFFEEEDFF);
// const _kPrimaryMid = Color(0xFF9C88FF);
// const _kGold = Color(0xFFFF9500);
// const _kGoldLight = Color(0xFFFFF4E0);
// const _kTextPrimary = Color(0xFF111827);
// const _kTextSecondary = Color(0xFF6B7280);
// const _kTextMuted = Color(0xFF9CA3AF);
// const _kBorder = Color(0xFFE5E7EB);
// const _kPageBg = Color(0xFFF9FAFB);
//
// class CheckinSection extends StatelessWidget {
//   const CheckinSection({super.key, required this.wp});
//
//   final WalletProvider wp;
//
//   static const int _visibleDays = 30;
//   static const double _dayBoxWidth = 52;
//   static const double _dayBoxHeight = 68;
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         final streakDay = wp.streakDay;
//         final checkedInToday = wp.checkedInToday;
//         final displayStreak = streakDay;
//
//         final nextBonus = WalletProvider.nextStreakBonusDay(streakDay);
//         final bonusCoins = nextBonus != null
//             ? WalletProvider.streakBonusForDay(nextBonus)
//             : 0;
//
//         final startDay = streakDay > 1 ? (streakDay - 1).clamp(1, 99) : 1;
//         final dayNumbers = List<int>.generate(
//           _visibleDays,
//           (i) => (startDay + i).clamp(1, 99),
//         );
//
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: _kBorder, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 24,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Header ────────────────────────────────────────────────────
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               _FlameIcon(active: displayStreak > 0),
//                               const SizedBox(width: 8),
//                               Text(
//                                 '$displayStreak',
//                                 style: const TextStyle(
//                                   fontSize: 36,
//                                   fontWeight: FontWeight.w800,
//                                   color: _kTextPrimary,
//                                   height: 1,
//                                 ),
//                               ),
//                               const SizedBox(width: 6),
//                               const Padding(
//                                 padding: EdgeInsets.only(bottom: 4),
//                                 child: Text(
//                                   'day streak',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: _kTextSecondary,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             displayStreak == 0
//                                 ? 'Start your streak today!'
//                                 : checkedInToday
//                                 ? 'Great job — come back tomorrow!'
//                                 : 'Check in to keep your streak alive!',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: _kTextMuted,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     _CoinsBadge(coins: Constant.checkinCoinsPerDay),
//                   ],
//                 ),
//               ),
//
//               // ── Milestone banner ──────────────────────────────────────────
//               if (nextBonus != null && bonusCoins > 0) ...[
//                 const SizedBox(height: 12),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _MilestoneBanner(
//                     daysLeft: nextBonus - streakDay,
//                     targetDay: nextBonus,
//                     bonusCoins: bonusCoins,
//                     checkedInToday: checkedInToday,
//                   ),
//                 ),
//               ],
//
//               const SizedBox(height: 16),
//
//               // ── Day scroll row ────────────────────────────────────────────
//               if (wp.loadingCheckin)
//                 const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 24),
//                   child: Center(
//                     child: SizedBox(
//                       height: 28,
//                       width: 28,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: _kPrimary,
//                       ),
//                     ),
//                   ),
//                 )
//               else
//                 _buildDayRow(
//                   context,
//                   wp,
//                   dayNumbers,
//                   streakDay,
//                   checkedInToday,
//                 ),
//
//               const SizedBox(height: 16),
//
//               // ── CTA button ────────────────────────────────────────────────
//               if (!wp.loadingCheckin)
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                   child: _CheckinButton(
//                     checkedInToday: checkedInToday,
//                     onTap: () => _doCheckin(context),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDayRow(
//     BuildContext context,
//     WalletProvider wp,
//     List<int> dayNumbers,
//     int streakDay,
//     bool checkedInToday,
//   ) {
//     final effectiveToday = streakDay > 0 ? streakDay : 1;
//     final items = <Widget>[];
//
//     for (int i = 0; i < dayNumbers.length; i++) {
//       final day = dayNumbers[i];
//       final isCompleted =
//           day < effectiveToday || (day == effectiveToday && checkedInToday);
//       final isTodayPending = day == effectiveToday && !checkedInToday;
//       final isFuture = day > effectiveToday;
//       final coins = _coinsForStreakDay(day);
//       final isBonusDay = _isStreakBonusDay(day);
//
//       if (i > 0) {
//         items.add(
//           SizedBox(
//             width: 8,
//             child: Center(
//               child: Container(
//                 height: 2,
//                 decoration: BoxDecoration(
//                   color: isCompleted ? _kPrimary.withOpacity(0.3) : _kBorder,
//                   borderRadius: BorderRadius.circular(1),
//                 ),
//               ),
//             ),
//           ),
//         );
//       }
//
//       items.add(
//         _DayBox(
//           dayNumber: day,
//           coins: coins,
//           isCompleted: isCompleted,
//           isTodayPending: isTodayPending,
//           isFuture: isFuture,
//           isBonusDay: isBonusDay,
//           boxWidth: _dayBoxWidth,
//           boxHeight: _dayBoxHeight,
//         ),
//       );
//     }
//
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(mainAxisSize: MainAxisSize.min, children: items),
//     );
//   }
//
//   Future<void> _doCheckin(BuildContext context) async {
//     final wp = context.read<WalletProvider>();
//     final err = await wp.doCheckin();
//     if (!context.mounted) return;
//     if (err != null) {
//       Get.snackbar('Check-in'.tr, err);
//     } else {
//       Get.snackbar(
//         'Check-in'.tr,
//         'You earned ${wp.checkinStatus?.coinsAwarded ?? Constant.checkinCoinsPerDay} coins!'
//             .tr,
//       );
//     }
//   }
// }
//
// // ── Sub-widgets ───────────────────────────────────────────────────────────────
//
// class _FlameIcon extends StatelessWidget {
//   const _FlameIcon({required this.active});
//
//   final bool active;
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         gradient: active
//             ? const LinearGradient(
//                 colors: [Color(0xFFFF6B35), Color(0xFFFFD93D)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               )
//             : null,
//         color: active ? null : _kBorder,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(
//         Icons.local_fire_department_rounded,
//         color: active ? Colors.white : _kTextMuted,
//         size: 22,
//       ),
//     );
//   }
// }
//
// class _CoinsBadge extends StatelessWidget {
//   const _CoinsBadge({required this.coins});
//
//   final int coins;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: _kGoldLight,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _kGold.withOpacity(0.3), width: 1),
//       ),
//       child: Column(
//         children: [
//           const Icon(Icons.monetization_on_rounded, color: _kGold, size: 20),
//           const SizedBox(height: 2),
//           Text(
//             '+$coins/day',
//             style: const TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               color: _kGold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _MilestoneBanner extends StatelessWidget {
//   const _MilestoneBanner({
//     required this.daysLeft,
//     required this.targetDay,
//     required this.bonusCoins,
//     required this.checkedInToday,
//   });
//
//   final int daysLeft;
//   final int targetDay;
//   final int bonusCoins;
//   final bool checkedInToday;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: _kGoldLight,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: _kGold.withOpacity(0.25), width: 1),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.emoji_events_rounded, color: _kGold, size: 16),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               daysLeft <= 0
//                   ? 'Claim your $bonusCoins coin bonus on day $targetDay!'
//                   : '$daysLeft day${daysLeft == 1 ? '' : 's'} until $bonusCoins bonus coins on day $targetDay',
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: _kGold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CheckinButton extends StatelessWidget {
//   const _CheckinButton({required this.checkedInToday, required this.onTap});
//
//   final bool checkedInToday;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: checkedInToday ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           gradient: checkedInToday
//               ? null
//               : const LinearGradient(
//                   colors: [_kPrimary, _kPrimaryMid],
//                   begin: Alignment.centerLeft,
//                   end: Alignment.centerRight,
//                 ),
//           color: checkedInToday ? _kPageBg : null,
//           borderRadius: BorderRadius.circular(16),
//           border: checkedInToday ? Border.all(color: _kBorder, width: 1) : null,
//           boxShadow: checkedInToday
//               ? null
//               : [
//                   BoxShadow(
//                     color: _kPrimary.withOpacity(0.35),
//                     blurRadius: 18,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               checkedInToday
//                   ? Icons.check_circle_outline_rounded
//                   : Icons.bolt_rounded,
//               color: checkedInToday ? _kTextMuted : Colors.white,
//               size: 20,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               checkedInToday
//                   ? "You're done for today!"
//                   : 'Check in & earn coins',
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//                 color: checkedInToday ? _kTextMuted : Colors.white,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ── Day Box ───────────────────────────────────────────────────────────────────
//
// class _DayBox extends StatelessWidget {
//   const _DayBox({
//     required this.dayNumber,
//     required this.coins,
//     required this.isCompleted,
//     required this.isTodayPending,
//     required this.isFuture,
//     required this.isBonusDay,
//     required this.boxWidth,
//     required this.boxHeight,
//   });
//
//   final int dayNumber;
//   final int coins;
//   final bool isCompleted;
//   final bool isTodayPending;
//   final bool isFuture;
//   final bool isBonusDay;
//   final double boxWidth;
//   final double boxHeight;
//
//   @override
//   Widget build(BuildContext context) {
//     final isActive = isTodayPending;
//
//     Color boxBg;
//     Gradient? boxGradient;
//     Border? boxBorder;
//     List<BoxShadow>? shadows;
//     Color iconColor;
//     Color textColor;
//     Color labelColor;
//     IconData icon;
//
//     if (isCompleted) {
//       boxGradient = const LinearGradient(
//         colors: [_kPrimary, _kPrimaryMid],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       );
//       boxBg = Colors.transparent;
//       boxBorder = null;
//       shadows = [
//         BoxShadow(
//           color: _kPrimary.withOpacity(0.3),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ];
//       iconColor = Colors.white;
//       textColor = Colors.white;
//       labelColor = _kTextSecondary;
//       icon = Icons.check_rounded;
//     } else if (isBonusDay) {
//       boxBg = _kGoldLight;
//       boxBorder = Border.all(color: _kGold, width: 1.5);
//       shadows = [
//         BoxShadow(
//           color: _kGold.withOpacity(0.2),
//           blurRadius: 12,
//           offset: const Offset(0, 3),
//         ),
//       ];
//       iconColor = _kGold;
//       textColor = _kGold;
//       labelColor = _kGold;
//       icon = Icons.emoji_events_rounded;
//     } else if (isActive) {
//       boxBg = _kPrimaryLight;
//       boxBorder = Border.all(color: _kPrimary, width: 2);
//       shadows = [
//         BoxShadow(
//           color: _kPrimary.withOpacity(0.2),
//           blurRadius: 14,
//           offset: const Offset(0, 4),
//           spreadRadius: 1,
//         ),
//       ];
//       iconColor = _kPrimary;
//       textColor = _kPrimary;
//       labelColor = _kPrimary;
//       icon = Icons.monetization_on_rounded;
//     } else {
//       // Future days
//       boxBg = _kPageBg;
//       boxBorder = Border.all(color: _kBorder, width: 1);
//       shadows = null;
//       iconColor = _kTextMuted;
//       textColor = _kTextMuted;
//       labelColor = _kTextMuted;
//       icon = Icons.monetization_on_rounded;
//     }
//
//     return SizedBox(
//       width: boxWidth,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // GOAL pill for bonus days
//           if (isBonusDay && !isCompleted)
//             Container(
//               margin: const EdgeInsets.only(bottom: 3),
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: _kGold,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: const Text(
//                 'GOAL',
//                 style: TextStyle(
//                   fontSize: 7,
//                   fontWeight: FontWeight.w800,
//                   color: Colors.white,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             )
//           else
//             const SizedBox(height: 12),
//
//           Container(
//             width: boxWidth,
//             height: boxWidth,
//             decoration: BoxDecoration(
//               gradient: boxGradient,
//               color: boxBg,
//               borderRadius: BorderRadius.circular(14),
//               border: boxBorder,
//               boxShadow: shadows,
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, color: iconColor, size: isBonusDay ? 20 : 18),
//                 const SizedBox(height: 2),
//                 Text(
//                   '+$coins',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                     color: textColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             isActive ? '▶ Day $dayNumber' : 'Day $dayNumber',
//             style: TextStyle(
//               fontSize: 9,
//               fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//               color: labelColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
