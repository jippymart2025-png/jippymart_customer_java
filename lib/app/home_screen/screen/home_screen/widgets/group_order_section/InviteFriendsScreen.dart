import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            icon: Icon(Icons.share_rounded, color: AppThemeData.grey900),
            onPressed: () => _copy(context, groupLink, 'Link'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 18),
            Text(
              'Share the link with your friends',
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'to start ordering together',
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
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
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Color(0xFFFF6B2C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shareIcon(
                  icon: Icons.chat_bubble_rounded,
                  color: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  onTap: () {},
                ),
                _shareIcon(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFFC13584),
                  label: 'Instagram',
                  onTap: () {},
                ),
                _shareIcon(
                  icon: Icons.sms_rounded,
                  color: const Color(0xFF34C759),
                  label: 'Messages',
                  onTap: () {},
                ),
                _shareIcon(
                  icon: Icons.more_horiz_rounded,
                  color: AppThemeData.grey800,
                  label: 'More',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F6),
                borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 2),
                        Text(
                          groupCode,
                          style: TextStyle(
                            fontFamily: AppThemeData.extraBold,
                            color: AppThemeData.grey900,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: AppThemeData.grey800,
                      size: 20,
                    ),
                    onPressed: () => _copy(context, groupCode, 'Group code'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
