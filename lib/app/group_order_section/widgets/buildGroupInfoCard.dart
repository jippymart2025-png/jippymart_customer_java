import 'package:flutter/material.dart';
import '../../../../../models/vendor_model.dart';
import '../../../../../themes/app_them_data.dart';

class GroupInfoCard extends StatelessWidget {
  final String invitationCode;
  final VendorModel? restaurant;

  const GroupInfoCard({
    super.key,
    required this.invitationCode,
    this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
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
          const SizedBox(height: 4),
          Text(
            invitationCode,
            style: TextStyle(
              fontFamily: AppThemeData.extraBold,
              color: AppThemeData.grey900,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          if (restaurant?.title != null) ...[
            const SizedBox(height: 12),
            Text(
              restaurant!.title!,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey800,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
