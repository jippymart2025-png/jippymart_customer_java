// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
// import 'package:jippymart_customer/app/wallet_screen/coin_ledger_screen.dart';
// import 'package:jippymart_customer/app/wallet_screen/redeem_coins_sheet.dart';
// import 'package:jippymart_customer/app/wallet_screen/referral_screen.dart';
// import 'package:jippymart_customer/app/wallet_screen/checkin_section.dart';
//
// class WalletHomeScreen extends StatefulWidget {
//   const WalletHomeScreen({super.key});
//
//   @override
//   State<WalletHomeScreen> createState() => _WalletHomeScreenState();
// }
//
// class _WalletHomeScreenState extends State<WalletHomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         final wp = context.read<WalletProvider>();
//         wp.refreshWallet();
//         wp.refreshCheckinStatus();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppThemeData.surface,
//       appBar: AppBar(
//         backgroundColor: AppThemeData.surface,
//         elevation: 0,
//         title: Text(
//           'Wallet'.tr,
//           style: TextStyle(
//             fontFamily: AppThemeData.semiBold,
//             fontSize: 18,
//             color: AppThemeData.grey900,
//           ),
//         ),
//       ),
//       body: Consumer<WalletProvider>(
//         builder: (context, wp, _) {
//           if (wp.loadingWallet && wp.coinWallet == null) {
//             return Center(child: Constant.loader(message: 'Loading wallet...'.tr));
//           }
//           if (wp.walletError != null && wp.coinWallet == null) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       wp.walletError!,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontFamily: AppThemeData.medium,
//                         color: AppThemeData.grey600,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextButton(
//                       onPressed: () => wp.refreshWallet(),
//                       child: Text('Retry'.tr),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }
//           return SingleChildScrollView(
//             padding: EdgeInsets.symmetric(
//               horizontal: Responsive.getScreenPadding(context).horizontal,
//               vertical: 16,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 _balanceCard(wp),
//                 const SizedBox(height: 20),
//                 _quickActions(wp),
//                 const SizedBox(height: 24),
//                 CheckinSection(wp: wp),
//                 const SizedBox(height: 24),
//                 _coinLedgerTile(wp),
//                 const SizedBox(height: 16),
//                 _referralTile(wp),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _balanceCard(WalletProvider wp) {
//     final coins = wp.coinBalance;
//     final moneyRupees = wp.moneyBalanceRupees;
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppThemeData.primary50,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppThemeData.primary200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Coin balance'.tr,
//             style: TextStyle(
//               fontFamily: AppThemeData.medium,
//               fontSize: 14,
//               color: AppThemeData.grey600,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '$coins coins',
//             style: TextStyle(
//               fontFamily: AppThemeData.semiBold,
//               fontSize: 24,
//               color: AppThemeData.grey900,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Wallet balance'.tr,
//             style: TextStyle(
//               fontFamily: AppThemeData.medium,
//               fontSize: 14,
//               color: AppThemeData.grey600,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             Constant.amountShow(amount: moneyRupees.toStringAsFixed(2)),
//             style: TextStyle(
//               fontFamily: AppThemeData.semiBold,
//               fontSize: 22,
//               color: AppThemeData.primary300,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _quickActions(WalletProvider wp) {
//     return Row(
//       children: [
//         Expanded(
//           child: _actionChip(
//             label: 'Redeem'.tr,
//             icon: Icons.card_giftcard,
//             onTap: () {
//               if (wp.coinBalance < Constant.minRedeemCoins) {
//                 Get.snackbar(
//                   'Redeem'.tr,
//                   'Minimum ${Constant.minRedeemCoins} coins required to redeem.'.tr,
//                 );
//                 return;
//               }
//               showModalBottomSheet<void>(
//                 context: context,
//                 isScrollControlled: true,
//                 backgroundColor: Colors.transparent,
//                 builder: (ctx) => RedeemCoinsSheet(
//                   currentCoins: wp.coinBalance,
//                   onRedeemed: () => wp.refreshWallet(),
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _actionChip(
//             label: 'Check-in'.tr,
//             icon: Icons.calendar_today,
//             onTap: () {
//               if (wp.checkedInToday) {
//                 Get.snackbar('Check-in'.tr, 'You have already checked in today.'.tr);
//                 return;
//               }
//               _doCheckin(wp);
//             },
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _actionChip(
//             label: 'Referral'.tr,
//             icon: Icons.share,
//             onTap: () => Get.to(() => const ReferralScreen()),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _actionChip({
//     required String label,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: AppThemeData.grey50,
//       borderRadius: BorderRadius.circular(12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           child: Column(
//             children: [
//               Icon(icon, color: AppThemeData.primary300, size: 28),
//               const SizedBox(height: 6),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.medium,
//                   fontSize: 13,
//                   color: AppThemeData.grey800,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _doCheckin(WalletProvider wp) async {
//     final err = await wp.doCheckin();
//     if (!mounted) return;
//     if (err != null) {
//       Get.snackbar('Check-in'.tr, err);
//     } else {
//       Get.snackbar(
//         'Check-in'.tr,
//         'You earned ${wp.checkinStatus?.coinsAwarded ?? Constant.checkinCoinsPerDay} coins!'.tr,
//       );
//     }
//   }
//
//   Widget _coinLedgerTile(WalletProvider wp) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       title: Text(
//         'Coin history'.tr,
//         style: TextStyle(
//           fontFamily: AppThemeData.semiBold,
//           fontSize: 16,
//           color: AppThemeData.grey900,
//         ),
//       ),
//       trailing: const Icon(Icons.chevron_right),
//       onTap: () {
//         Get.to(() => const CoinLedgerScreen());
//       },
//     );
//   }
//
//   Widget _referralTile(WalletProvider wp) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       title: Text(
//         'Referral & rewards'.tr,
//         style: TextStyle(
//           fontFamily: AppThemeData.semiBold,
//           fontSize: 16,
//           color: AppThemeData.grey900,
//         ),
//       ),
//       trailing: const Icon(Icons.chevron_right),
//       onTap: () => Get.to(() => const ReferralScreen()),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
import 'package:jippymart_customer/app/wallet_screen/coin_ledger_screen.dart';
import 'package:jippymart_customer/app/wallet_screen/redeem_coins_sheet.dart';
import 'package:jippymart_customer/app/wallet_screen/referral_screen.dart';
import 'package:jippymart_customer/app/wallet_screen/checkin_section.dart';
import 'package:jippymart_customer/utils/coin_sound.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _W {
  // Brand
  static const Color red = Color(0xFFE23744);
  static const Color redDark = Color(0xFFC0000F);
  static const Color redLight = Color(0xFFFFF0F1);

  // Coin gold
  static const Color gold = Color(0xFFFF9500);
  static const Color goldLight = Color(0xFFFFF8EC);
  static const Color goldDark = Color(0xFFD4780A);

  // Money green
  static const Color green = Color(0xFF26A541);
  static const Color greenLight = Color(0xFFEEFBF1);

  // Neutrals
  static const Color bg = Color(0xFFF7F7F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text1 = Color(0xFF1C1C1E);
  static const Color text2 = Color(0xFF6D6D6D);
  static const Color text3 = Color(0xFFAAAAAA);
  static const Color divider = Color(0xFFF0F0F0);

  static const double radius = 20;
  static const double cardRadius = 16;
}

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _isCheckinInProgress = false;
  bool _isRedeemSheetOpen = false;
   DateTime? _lastSnackAt;
   String? _lastSnackKey;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wp = context.read<WalletProvider>();
      wp.refreshWallet();
      wp.refreshCheckinStatus();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _W.bg,
      body: Consumer<WalletProvider>(
        builder: (context, wp, _) {
          // ── Loading ──
          if (wp.loadingWallet && wp.coinWallet == null) {
            return _LoadingView(fadeAnim: _fadeAnim);
          }

          // ── Error ──
          if (wp.walletError != null && wp.coinWallet == null) {
            return _ErrorView(
              message: wp.walletError!,
              onRetry: () => wp.refreshWallet(force: true),
            );
          }

          // ── Content ──
          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getScreenPadding(
                        context,
                      ).horizontal,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),
                        _BalanceHeroCard(wp: wp),
                        const SizedBox(height: 20),
                        _QuickActionsRow(
                          wp: wp,
                          onRedeem: () => _openRedeemSheet(wp),
                          onCheckin: () => _doCheckin(wp),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(title: 'Daily Rewards'),
                        const SizedBox(height: 12),
                        CheckinSection(
                          wp: wp,
                          onCheckin: () => _doCheckin(wp),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(title: 'Activity'),
                        const SizedBox(height: 12),
                        _NavTile(
                          icon: Icons.receipt_long_rounded,
                          iconColor: _W.red,
                          iconBg: _W.redLight,
                          label: 'Coin History',
                          subtitle: 'View all your coin transactions',
                          onTap: () => Get.to(() => const CoinLedgerScreen()),
                        ),
                        const SizedBox(height: 10),
                        _NavTile(
                          icon: Icons.people_alt_outlined,
                          iconColor: _W.green,
                          iconBg: _W.greenLight,
                          label: 'Referral & Rewards',
                          subtitle: 'Invite friends, earn together',
                          onTap: () => Get.to(() => const ReferralScreen()),
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Sliver AppBar ──────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: _W.bg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: _W.text1,
        ),
      ),
      title: Text(
        'Wallet',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _W.text1,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {
            final wp = context.read<WalletProvider>();
            wp.refreshWallet(force: true);
            wp.refreshCheckinStatus();
          },
          icon: const Icon(Icons.refresh_rounded, size: 20, color: _W.text2),
        ),
      ],
    );
  }

  void _showSnackOnce({
    required String key,
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final now = DateTime.now();
    if (_lastSnackKey == key &&
        _lastSnackAt != null &&
        now.difference(_lastSnackAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastSnackKey = key;
    _lastSnackAt = now;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: textColor,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ─── Check-in handler ───────────────────────────────────────────────────────
  Future<void> _doCheckin(WalletProvider wp) async {
    if (_isCheckinInProgress) {
      return;
    }
    if (wp.checkedInToday) {
      _showSnackOnce(
        key: 'already_checked_in',
        title: 'Already Checked In',
        message: 'Come back tomorrow for more coins!',
        backgroundColor: _W.card,
        textColor: _W.text1,
      );
      return;
    }
    _isCheckinInProgress = true;
    final err = await wp.doCheckin();
    if (!mounted) {
      _isCheckinInProgress = false;
      return;
    }
    _isCheckinInProgress = false;
    if (err != null) {
      _showSnackOnce(
        key: 'checkin_failed',
        title: 'Check-in Failed',
        message: err,
        backgroundColor: _W.redLight,
        textColor: _W.red,
      );
    } else {
      playCoinSound();
      _showSnackOnce(
        key: 'checkin_success',
        title: '🎉 Checked In!',
        message:
            'You earned ${wp.checkinStatus?.coinsAwarded ?? Constant.checkinCoinsPerDay} coins!',
        backgroundColor: _W.goldLight,
        textColor: _W.goldDark,
      );
    }
  }

  // ─── Redeem handler ────────────────────────────────────────────────────────
  void _openRedeemSheet(WalletProvider wp) {
    if (wp.coinBalance < Constant.minRedeemCoins) {
      _showSnackOnce(
        key: 'not_enough_coins',
        title: 'Not enough coins',
        message: 'Minimum ${Constant.minRedeemCoins} coins required.',
        backgroundColor: _W.redLight,
        textColor: _W.red,
      );
      return;
    }
    if (_isRedeemSheetOpen) return;
    _isRedeemSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RedeemCoinsSheet(
        currentCoins: wp.coinBalance,
        onRedeemed: () => wp.refreshWallet(force: true),
      ),
    ).whenComplete(() {
      _isRedeemSheetOpen = false;
    });
  }
}

// ─── Balance Hero Card ────────────────────────────────────────────────────────
class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({required this.wp});

  final WalletProvider wp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_W.radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle — top right
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'JippyMart Wallet',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Two balance columns
                Row(
                  children: [
                    Expanded(
                      child: _BalancePill(
                        icon: Icons.monetization_on_rounded,
                        iconColor: _W.gold,
                        label: 'Coins',
                        value: '${wp.coinBalance}',
                        valueColor: _W.gold,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _BalancePill(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: _W.green,
                        label: 'Balance',
                        value: Constant.amountShow(
                          amount: wp.moneyBalanceRupees.toStringAsFixed(2),
                        ),
                        valueColor: _W.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.wp,
    required this.onRedeem,
    required this.onCheckin,
  });

  final WalletProvider wp;
  final VoidCallback onRedeem;
  final VoidCallback onCheckin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.card_giftcard_rounded,
            label: 'Redeem',
            iconColor: _W.red,
            bgColor: _W.redLight,
            onTap: onRedeem,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.today_rounded,
            label: 'Check-in',
            iconColor: _W.gold,
            bgColor: _W.goldLight,
            badge: wp.checkedInToday ? '✓' : null,
            onTap: onCheckin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Refer',
            iconColor: _W.green,
            bgColor: _W.greenLight,
            onTap: () => Get.to(() => const ReferralScreen()),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _W.card,
      borderRadius: BorderRadius.circular(_W.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_W.cardRadius),
        splashColor: bgColor,
        highlightColor: bgColor.withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_W.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _W.text1,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _W.text3,
        letterSpacing: 1.3,
      ),
    );
  }
}

// ─── Navigation Tile ──────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _W.card,
      borderRadius: BorderRadius.circular(_W.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_W.cardRadius),
        splashColor: iconBg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_W.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _W.text1,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _W.text3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _W.text3,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.fadeAnim});

  final Animation<double> fadeAnim;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _W.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Shimmer-like placeholder header
            Container(
              height: 180,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(_W.radius),
              ),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: _W.red,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _W.bg,
      appBar: AppBar(
        backgroundColor: _W.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _W.text1,
          ),
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _W.text1,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _W.redLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: _W.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _W.text1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _W.text2),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _W.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
