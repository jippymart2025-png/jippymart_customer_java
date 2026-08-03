import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

import 'join_group_order_screen.dart';

class InviteFriendsScreen extends StatelessWidget {
  final String groupCode;
  final String groupLink;
  final VendorModel restaurant;
  final int groupOrdersInvitationId;
  final int hostCustomerId;

  const InviteFriendsScreen({
    super.key,
    required this.groupCode,
    required this.groupLink,
    required this.restaurant,
    required this.groupOrdersInvitationId,
    required this.hostCustomerId,
  });

  // The message that gets shared everywhere. Adjust `restaurant.title`
  // if your VendorModel uses a different field name for the name.
  String get _shareMessage =>
      'Join my group order on ${restaurant.title} 🍔\n\n'
      'Tap the link to add your items:\n$groupLink\n\n'
      'Or enter group code: $groupCode';

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ---- Share handlers ------------------------------------------------------

  Future<void> _openOrShare(Uri uri, {required BuildContext context}) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _shareSheet();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App not available, opening share…')),
        );
      }
      _shareSheet();
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}',
    );
    return _openOrShare(uri, context: context);
  }

  Future<void> _shareMessages(BuildContext context) {
    // sms: with a body param works on both iOS and Android.
    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(_shareMessage)}');
    return _openOrShare(uri, context: context);
  }

  // Instagram has no text-share URL scheme, so we fall back to the
  // system share sheet where Instagram shows up as a target.
  Future<void> _shareInstagram(BuildContext context) => _shareSheet();

  Future<void> _shareSheet() =>
      Share.share(_shareMessage, subject: 'Group order invite');

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppThemeData.grey900,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Invite Friends',
          style: TextStyle(
            fontFamily: AppThemeData.extraBold,
            color: AppThemeData.grey900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: AppThemeData.grey900),
            onPressed: _shareSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              // ---- Hero -----------------------------------------------------
              Container(
                height: 108,
                width: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppThemeData.primary1000.withOpacity(0.12),
                      AppThemeData.primary1000.withOpacity(0.04),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 20),
              Text(
                'Share the link with your friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey900,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'to start ordering together',
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 26),

              // ---- Link box -------------------------------------------------
              Container(
                padding: const EdgeInsets.only(left: 16, right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDEDEF)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 18,
                      color: AppThemeData.grey500,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        groupLink,
                        style: TextStyle(
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.grey800,
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _copy(context, groupLink, 'Link'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppThemeData.primary1000,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Copy',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ---- Share via ------------------------------------------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share via',
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shareIcon(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366),
                    label: 'WhatsApp',
                    onTap: () => _shareWhatsApp(context),
                  ),
                  _shareIcon(
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFC13584),
                    label: 'Instagram',
                    onTap: () => _shareInstagram(context),
                  ),
                  _shareIcon(
                    icon: Icons.sms_rounded,
                    color: const Color(0xFF34C759),
                    label: 'Messages',
                    onTap: () => _shareMessages(context),
                  ),
                  _shareIcon(
                    icon: Icons.more_horiz_rounded,
                    color: AppThemeData.grey800,
                    label: 'More',
                    onTap: _shareSheet,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ---- Group code card -----------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                decoration: BoxDecoration(
                  color: AppThemeData.primary1000.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppThemeData.primary1000.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group code',
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              color: AppThemeData.grey500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            groupCode,
                            style: TextStyle(
                              fontFamily: AppThemeData.extraBold,
                              color: AppThemeData.grey900,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        color: AppThemeData.primary1000,
                        size: 20,
                      ),
                      onPressed: () => _copy(context, groupCode, 'Group code'),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ---- Continue -------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary1000,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.to(
                      () => JoinGroupOrderScreen(
                        groupOrdersInvitationId: groupOrdersInvitationId,
                        invitationCode: groupCode,
                        restaurant: restaurant,
                        hostCustomerId: hostCustomerId,
                      ),
                    );
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareIcon({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: color.withOpacity(0.12),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Icon(icon, color: color, size: 23),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            color: AppThemeData.grey800,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
