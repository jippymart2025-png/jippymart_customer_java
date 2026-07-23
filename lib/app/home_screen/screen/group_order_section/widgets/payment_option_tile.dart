import 'package:flutter/material.dart';

import '../../../../../themes/app_them_data.dart';
import '../screens/create_group_order.dart'; // or wherever GroupPaymentMode is

class PaymentOptionTile extends StatelessWidget {
  final GroupPaymentMode mode;
  final GroupPaymentMode selectedMode;
  final String title;
  final ValueChanged<GroupPaymentMode> onChanged;

  const PaymentOptionTile({
    super.key,
    required this.mode,
    required this.selectedMode,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMode == mode;

    return InkWell(
      onTap: () => onChanged(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B2C) : AppThemeData.grey100,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFFFF6B2C)
                  : AppThemeData.grey500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (mode == GroupPaymentMode.hostPays)
              Icon(Icons.chevron_right_rounded, color: AppThemeData.grey500),
          ],
        ),
      ),
    );
  }
}
