// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
//
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/referral_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
//
// class ReferralScreen extends StatefulWidget {
//   const ReferralScreen({super.key});
//
//   @override
//   State<ReferralScreen> createState() => _ReferralScreenState();
// }
//
// class _ReferralScreenState extends State<ReferralScreen> {
//   final TextEditingController _codeController = TextEditingController();
//   bool _applying = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         context.read<WalletProvider>().refreshWallet();
//         context.read<WalletProvider>().refreshMyReferrals();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _codeController.dispose();
//     super.dispose();
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
//           'Referral'.tr,
//           style: TextStyle(
//             fontFamily: AppThemeData.semiBold,
//             fontSize: 18,
//             color: AppThemeData.grey900,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _myCodeCard(),
//             const SizedBox(height: 24),
//             _applyCodeSection(),
//             const SizedBox(height: 24),
//             _myReferralsSection(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _myCodeCard() {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         final id = Constant.userModel?.id ?? '';
//         final code = wp.referralCode ?? (id.length >= 8 ? id.substring(0, 8) : (id.isNotEmpty ? id : '------'));
//         return Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: AppThemeData.primary50,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: AppThemeData.primary200),
//           ),
//           child: Column(
//             children: [
//               Text(
//                 'Your referral code'.tr,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.medium,
//                   fontSize: 14,
//                   color: AppThemeData.grey600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               SelectableText(
//                 code,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.semiBold,
//                   fontSize: 22,
//                   letterSpacing: 2,
//                   color: AppThemeData.grey900,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: () {
//                     Share.share(
//                       'Use my referral code $code on JippyMart to get rewards!',
//                       subject: 'Referral code',
//                     );
//                   },
//                   icon: const Icon(Icons.share, size: 20),
//                   label: Text('Share code'.tr),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppThemeData.primary300,
//                     side: BorderSide(color: AppThemeData.primary300),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _applyCodeSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Apply a referral code'.tr,
//           style: TextStyle(
//             fontFamily: AppThemeData.semiBold,
//             fontSize: 16,
//             color: AppThemeData.grey900,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _codeController,
//                 decoration: InputDecoration(
//                   hintText: 'Enter code'.tr,
//                   border: const OutlineInputBorder(),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             ElevatedButton(
//               onPressed: _applying ? null : _applyCode,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppThemeData.primary300,
//                 foregroundColor: Colors.white,
//               ),
//               child: _applying
//                   ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                     )
//                   : Text('Apply'.tr),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _applyCode() async {
//     final code = _codeController.text.trim();
//     if (code.isEmpty) {
//       ShowToastDialog.showToast('Please enter a code.'.tr);
//       return;
//     }
//     setState(() => _applying = true);
//     final wp = context.read<WalletProvider>();
//     final err = await wp.applyReferralCode(
//       code: code,
//       idempotencyKey: 'apply_${code}_${DateTime.now().millisecondsSinceEpoch}',
//     );
//     setState(() => _applying = false);
//     if (!mounted) return;
//     if (err != null) {
//       ShowToastDialog.showToast(err);
//     } else {
//       ShowToastDialog.showToast('Code applied successfully.'.tr);
//       _codeController.clear();
//     }
//   }
//
//   Widget _myReferralsSection() {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         if (wp.loadingReferrals && wp.myReferrals.isEmpty) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.all(24),
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }
//         final list = wp.myReferrals;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'My referrals'.tr,
//               style: TextStyle(
//                 fontFamily: AppThemeData.semiBold,
//                 fontSize: 16,
//                 color: AppThemeData.grey900,
//               ),
//             ),
//             const SizedBox(height: 12),
//             if (list.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   'No referrals yet.'.tr,
//                   style: TextStyle(
//                     fontFamily: AppThemeData.medium,
//                     color: AppThemeData.grey600,
//                   ),
//                 ),
//               )
//             else
//               ...list.map((r) => _ReferralTile(referral: r)),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class _ReferralTile extends StatelessWidget {
//   const _ReferralTile({required this.referral});
//   final ReferralModel referral;
//
//   @override
//   Widget build(BuildContext context) {
//     final status = referral.status ?? 'PENDING';
//     final statusColor = status == 'REWARDED'
//         ? AppThemeData.success500
//         : status == 'QUALIFIED'
//             ? AppThemeData.primary300
//             : AppThemeData.grey600;
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ListTile(
//         title: Text(
//           referral.codeUsed ?? referral.referralCode ?? '—',
//           style: TextStyle(
//             fontFamily: AppThemeData.medium,
//             fontSize: 15,
//             color: AppThemeData.grey900,
//           ),
//         ),
//         subtitle: Text(
//           'Status: $status',
//           style: TextStyle(
//             fontFamily: AppThemeData.regular,
//             fontSize: 13,
//             color: statusColor,
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
//
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/referral_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
//
// class ReferralScreen extends StatefulWidget {
//   const ReferralScreen({super.key});
//
//   @override
//   State<ReferralScreen> createState() => _ReferralScreenState();
// }
//
// class _ReferralScreenState extends State<ReferralScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController _codeController = TextEditingController();
//   bool _applying = false;
//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
//     _animController.forward();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         context.read<WalletProvider>().refreshWallet();
//         context.read<WalletProvider>().refreshMyReferrals();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _codeController.dispose();
//     _animController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final sw = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FB),
//       appBar: _buildAppBar(),
//       body: FadeTransition(
//         opacity: _fadeAnim,
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           padding: EdgeInsets.symmetric(horizontal: sw * 0.045, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _HeroCodeCard(codeController: _codeController),
//               const SizedBox(height: 20),
//               _ApplyCodeCard(
//                 codeController: _codeController,
//                 applying: _applying,
//                 onApply: _applyCode,
//               ),
//               const SizedBox(height: 20),
//               _ReferralsSection(),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: const Color(0xFFF8F9FB),
//       elevation: 0,
//       surfaceTintColor: Colors.transparent,
//       leading: IconButton(
//         icon: Container(
//           width: 38,
//           height: 38,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: const Icon(
//             Icons.arrow_back_ios_new_rounded,
//             size: 16,
//             color: Color(0xFF1A1A2E),
//           ),
//         ),
//         onPressed: () => Get.back(),
//       ),
//       title: Text(
//         'Refer & Earn'.tr,
//         style: TextStyle(
//           fontFamily: AppThemeData.semiBold,
//           fontSize: 18,
//           fontWeight: FontWeight.w700,
//           color: const Color(0xFF1A1A2E),
//           letterSpacing: -0.3,
//         ),
//       ),
//       centerTitle: true,
//     );
//   }
//
//   Future<void> _applyCode() async {
//     final code = _codeController.text.trim();
//     if (code.isEmpty) {
//       ShowToastDialog.showToast('Please enter a code.'.tr);
//       return;
//     }
//     setState(() => _applying = true);
//     final wp = context.read<WalletProvider>();
//     final err = await wp.applyReferralCode(
//       code: code,
//       idempotencyKey: 'apply_${code}_${DateTime.now().millisecondsSinceEpoch}',
//     );
//     setState(() => _applying = false);
//     if (!mounted) return;
//     if (err != null) {
//       ShowToastDialog.showToast(err);
//     } else {
//       ShowToastDialog.showToast('Code applied successfully! 🎉'.tr);
//       _codeController.clear();
//     }
//   }
// }
//
// // ── Hero Code Card ────────────────────────────────────────────────
// class _HeroCodeCard extends StatelessWidget {
//   final TextEditingController codeController;
//
//   const _HeroCodeCard({required this.codeController});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         final id = Constant.userModel?.id ?? '';
//         final code =
//             wp.referralCode ??
//             (id.length >= 8
//                 ? id.substring(0, 8)
//                 : (id.isNotEmpty ? id : '------'));
//
//         return Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(24),
//             gradient: const LinearGradient(
//               colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF0F3460).withOpacity(0.4),
//                 blurRadius: 28,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Stack(
//             children: [
//               // Background decorative circles
//               Positioned(
//                 top: -30,
//                 right: -30,
//                 child: Container(
//                   width: 130,
//                   height: 130,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.04),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: -20,
//                 left: -20,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.03),
//                   ),
//                 ),
//               ),
//
//               Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   children: [
//                     // Top badge
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.15),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.card_giftcard_rounded,
//                             size: 14,
//                             color: Color(0xFFFFD700),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             'Invite friends, earn rewards'.tr,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.white70,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     Text(
//                       'Your Referral Code'.tr,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.white54,
//                         fontWeight: FontWeight.w500,
//                         letterSpacing: 0.3,
//                       ),
//                     ),
//
//                     const SizedBox(height: 10),
//
//                     // Code display
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 14,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.2),
//                           width: 1.5,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SelectableText(
//                             code.toUpperCase(),
//                             style: const TextStyle(
//                               fontSize: 26,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.white,
//                               letterSpacing: 6,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           GestureDetector(
//                             onTap: () {
//                               Clipboard.setData(ClipboardData(text: code));
//                               ShowToastDialog.showToast('Code copied!'.tr);
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.15),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Icon(
//                                 Icons.copy_rounded,
//                                 size: 16,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Share button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           Share.share(
//                             '🎉 Get Rewards on JippyMart!\n\n'
//                             'Use my referral code:\n\n'
//                             '👉 $code 👈\n\n'
//                             'Copy this code and paste it while signing up!',
//                             subject: 'JippyMart Referral Code',
//                           );
//                         },
//                         icon: const Icon(Icons.ios_share_rounded, size: 18),
//                         label: Text(
//                           'Share with Friends'.tr,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: 0.2,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppThemeData.primary300,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           elevation: 0,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// // ── Apply Code Card ───────────────────────────────────────────────
// class _ApplyCodeCard extends StatelessWidget {
//   final TextEditingController codeController;
//   final bool applying;
//   final VoidCallback onApply;
//
//   const _ApplyCodeCard({
//     required this.codeController,
//     required this.applying,
//     required this.onApply,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 16,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: AppThemeData.primary50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.redeem_rounded,
//                   color: AppThemeData.primary300,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Have a referral code?'.tr,
//                     style: TextStyle(
//                       fontFamily: AppThemeData.semiBold,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: const Color(0xFF1A1A2E),
//                     ),
//                   ),
//                   Text(
//                     'Enter it below to claim your reward'.tr,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF9CA3AF),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: codeController,
//                   textCapitalization: TextCapitalization.characters,
//                   style: TextStyle(
//                     fontFamily: AppThemeData.semiBold,
//                     fontSize: 15,
//                     letterSpacing: 1.5,
//                     color: const Color(0xFF1A1A2E),
//                   ),
//                   decoration: InputDecoration(
//                     hintText: 'e.g. ABC12345'.tr,
//                     hintStyle: const TextStyle(
//                       color: Color(0xFFD1D5DB),
//                       letterSpacing: 0.5,
//                       fontSize: 14,
//                     ),
//                     prefixIcon: const Icon(
//                       Icons.tag_rounded,
//                       color: Color(0xFF9CA3AF),
//                       size: 20,
//                     ),
//                     filled: true,
//                     fillColor: const Color(0xFFF9FAFB),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 14,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: BorderSide(
//                         color: AppThemeData.primary300,
//                         width: 1.5,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               SizedBox(
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: applying ? null : onApply,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppThemeData.primary300,
//                     foregroundColor: Colors.white,
//                     disabledBackgroundColor: AppThemeData.primary300
//                         .withOpacity(0.5),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 0,
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                   ),
//                   child: applying
//                       ? const SizedBox(
//                           height: 18,
//                           width: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text(
//                           'Apply'.tr,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ── Referrals Section ─────────────────────────────────────────────
// class _ReferralsSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Section header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'My Referrals'.tr,
//                   style: TextStyle(
//                     fontFamily: AppThemeData.semiBold,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: const Color(0xFF1A1A2E),
//                   ),
//                 ),
//                 if (wp.myReferrals.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppThemeData.primary50,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       '${wp.myReferrals.length} ${'total'.tr}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: AppThemeData.primary300,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             // Content
//             if (wp.loadingReferrals && wp.myReferrals.isEmpty)
//               _buildLoadingState()
//             else if (wp.myReferrals.isEmpty)
//               _buildEmptyState()
//             else
//               ...wp.myReferrals.map((r) => _ReferralTile(referral: r)),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Container(
//       height: 120,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 36),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF3F4F6),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.group_add_outlined,
//               size: 30,
//               color: Color(0xFF9CA3AF),
//             ),
//           ),
//           const SizedBox(height: 14),
//           Text(
//             'No referrals yet'.tr,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF1A1A2E),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Share your code and start earning!'.tr,
//             style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ── Referral Tile ─────────────────────────────────────────────────
// class _ReferralTile extends StatelessWidget {
//   const _ReferralTile({required this.referral});
//
//   final ReferralModel referral;
//
//   @override
//   Widget build(BuildContext context) {
//     final status = referral.status ?? 'PENDING';
//
//     final statusConfig = _statusConfig(status);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Avatar
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: statusConfig['bgColor'] as Color,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               statusConfig['icon'] as IconData,
//               color: statusConfig['color'] as Color,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//
//           // Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   referral.codeUsed ?? referral.referralCode ?? '—',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1A1A2E),
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   statusConfig['label'] as String,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: statusConfig['color'] as Color,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Status badge
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: statusConfig['bgColor'] as Color,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               status,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//                 color: statusConfig['color'] as Color,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Map<String, dynamic> _statusConfig(String status) {
//     switch (status) {
//       case 'REWARDED':
//         return {
//           'color': const Color(0xFF16A34A),
//           'bgColor': const Color(0xFFF0FDF4),
//           'icon': Icons.check_circle_rounded,
//           'label': 'Reward credited to wallet',
//         };
//       case 'QUALIFIED':
//         return {
//           'color': AppThemeData.primary300,
//           'bgColor': AppThemeData.primary50,
//           'icon': Icons.verified_rounded,
//           'label': 'Qualified — reward pending',
//         };
//       default:
//         return {
//           'color': const Color(0xFF6B7280),
//           'bgColor': const Color(0xFFF9FAFB),
//           'icon': Icons.hourglass_top_rounded,
//           'label': 'Waiting for activity',
//         };
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/referral_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';

// ── Const shadows ─────────────────────────────────────────────────
const _heroShadow = [
  BoxShadow(color: Color(0x66143060), blurRadius: 28, offset: Offset(0, 10)),
];
const _cardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4)),
];
const _tileShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
];
const _appBarIconShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
];

const _heroGradient = LinearGradient(
  colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Typed status config ───────────────────────────────────────────
class _StatusConfig {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.label,
  });
}

// `final` not `const` — AppThemeData values are runtime
final _statusConfigs = <String, _StatusConfig>{
  'REWARDED': const _StatusConfig(
    color: Color(0xFF16A34A),
    bgColor: Color(0xFFF0FDF4),
    icon: Icons.check_circle_rounded,
    label: 'Reward credited to wallet',
  ),
  'QUALIFIED': _StatusConfig(
    color: AppThemeData.primary300,
    bgColor: AppThemeData.primary50,
    icon: Icons.verified_rounded,
    label: 'Qualified — reward pending',
  ),
};

const _defaultStatusConfig = _StatusConfig(
  color: Color(0xFF6B7280),
  bgColor: Color(0xFFF9FAFB),
  icon: Icons.hourglass_top_rounded,
  label: 'Waiting for activity',
);

// ─────────────────────────────────────────────────────────────────
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _applying = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fix: single provider read, two method calls
      final wp = context.read<WalletProvider>();
      wp.refreshWallet();
      wp.refreshMyReferrals();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fix: compute ONCE, reuse everywhere — single MediaQuery subscription
    final hPad = MediaQuery.sizeOf(context).width * 0.045;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          // Fix: pull-to-refresh restored
          color: AppThemeData.primary300,
          onRefresh: () async {
            final wp = context.read<WalletProvider>();
            wp.refreshWallet();
            wp.refreshMyReferrals();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Hero + Apply section ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fix: const constructor now usable
                      const _HeroCodeCard(),
                      const SizedBox(height: 20),
                      _ApplyCodeCard(
                        codeController: _codeController,
                        applying: _applying,
                        onApply: _applyCode,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── My Referrals header ───────────────────────────
              Consumer<WalletProvider>(
                builder: (context, wp, _) {
                  final referrals = wp.myReferrals;
                  if (referrals.isEmpty) return const SliverToBoxAdapter();

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Referrals'.tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${referrals.length} ${'total'.tr}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppThemeData.primary300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Referrals list / loading / empty ──────────────
              Consumer<WalletProvider>(
                builder: (context, wp, _) {
                  final referrals = wp.myReferrals;

                  // Fix: SliverToBoxAdapter instead of SliverFillRemaining
                  // so it doesn't fight with already-rendered top slivers
                  if (wp.loadingReferrals && referrals.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Container(
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    );
                  }

                  if (referrals.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3F4F6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.group_add_outlined,
                                  size: 30,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No referrals yet'.tr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Share your code and start earning!'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Fix: RepaintBoundary added per tile
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => RepaintBoundary(
                          child: _ReferralTile(referral: referrals[index]),
                        ),
                        childCount: referrals.length,
                      ),
                    ),
                  );
                },
              ),

              // Bottom safe area padding
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FB),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: _appBarIconShadow,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Refer & Earn'.tr,
        style: TextStyle(
          fontFamily: AppThemeData.semiBold,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ShowToastDialog.showToast('Please enter a code.'.tr);
      return;
    }
    setState(() => _applying = true);
    final wp = context.read<WalletProvider>();
    final err = await wp.applyReferralCode(
      code: code,
      idempotencyKey: 'apply_${code}_${DateTime.now().millisecondsSinceEpoch}',
    );
    setState(() => _applying = false);
    if (!mounted) return;
    if (err != null) {
      ShowToastDialog.showToast(err);
    } else {
      ShowToastDialog.showToast('Code applied successfully! 🎉'.tr);
      _codeController.clear();
    }
  }
}

// ── Hero Code Card ────────────────────────────────────────────────
class _HeroCodeCard extends StatelessWidget {
  // Fix: const constructor so call site can use `const _HeroCodeCard()`
  const _HeroCodeCard();

  static const _codeBoxDecoration = BoxDecoration(
    color: Color(0x1AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x33FFFFFF), width: 1.5),
    ),
  );

  static const _badgeDecoration = BoxDecoration(
    color: Color(0x1AFFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: Border.fromBorderSide(BorderSide(color: Color(0x26FFFFFF))),
  );

  static const _copyBtnDecoration = BoxDecoration(
    color: Color(0x26FFFFFF),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wp, _) {
        final id = Constant.userModel?.id ?? '';
        final code =
            wp.referralCode ??
            (id.length >= 8
                ? id.substring(0, 8)
                : (id.isNotEmpty ? id : '------'));

        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            gradient: _heroGradient,
            boxShadow: _heroShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x0AFFFFFF),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x08FFFFFF),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: _badgeDecoration,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            size: 14,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Invite friends, earn rewards'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Your Referral Code'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: _codeBoxDecoration,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableText(
                            code.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ShowToastDialog.showToast('Code copied!'.tr);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: _copyBtnDecoration,
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            'Use my referral code $code on JippyMart to get rewards!',
                            subject: 'Referral code',
                          );
                        },
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text(
                          'Share with Friends'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Apply Code Card ───────────────────────────────────────────────
class _ApplyCodeCard extends StatelessWidget {
  final TextEditingController codeController;
  final bool applying;
  final VoidCallback onApply;

  const _ApplyCodeCard({
    required this.codeController,
    required this.applying,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppThemeData.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.redeem_rounded,
                  color: AppThemeData.primary300,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have a referral code?'.tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Enter it below to claim your reward'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 15,
                    letterSpacing: 1.5,
                    color: const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. ABC12345'.tr,
                    hintStyle: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      letterSpacing: 0.5,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppThemeData.primary300,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: applying ? null : onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary300,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppThemeData.primary300
                        .withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: applying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Apply'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Referral Tile ─────────────────────────────────────────────────
class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.referral});

  final ReferralModel referral;

  @override
  Widget build(BuildContext context) {
    final status = referral.status ?? 'PENDING';
    final config = _statusConfigs[status] ?? _defaultStatusConfig;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: _tileShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 20),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.codeUsed ?? referral.referralCode ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.label.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: config.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: config.color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
