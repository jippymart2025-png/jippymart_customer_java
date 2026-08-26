import 'package:flutter/material.dart';

import '../../Communityscreen/theme/app_theme.dart';

class BankOfferCard extends StatelessWidget {
  final String bankName;
  final String offerTitle;
  final String offerSubtitle;
  final String saveText;

  const BankOfferCard({
    super.key,
    required this.bankName,
    required this.offerTitle,
    required this.offerSubtitle,
    required this.saveText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const _HdfcLogo(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offerTitle,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offerSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    saveText,
                    style: const TextStyle(
                      color: Color(0xFF268344),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HdfcLogo extends StatelessWidget {
  const _HdfcLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE31E24), width: 2.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            height: 13,
            width: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF17559A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
