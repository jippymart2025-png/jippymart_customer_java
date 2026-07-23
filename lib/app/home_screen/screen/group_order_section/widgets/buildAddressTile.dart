import 'package:flutter/material.dart';
import '../../../../../models/user_model.dart';
import '../../../../../themes/app_them_data.dart';

class AddressTile extends StatelessWidget {
  final ShippingAddress address;
  final ShippingAddress? selectedAddress;
  final bool isJoining;
  final String Function(ShippingAddress) addressLabel;
  final ValueChanged<ShippingAddress> onSelected;

  const AddressTile({
    super.key,
    required this.address,
    required this.selectedAddress,
    required this.isJoining,
    required this.addressLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedAddress?.id == address.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isJoining ? null : () => onSelected(address),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFF6B2C)
                    : const Color(0xFFEEEEF2),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? const Color(0xFFFF6B2C)
                      : AppThemeData.grey400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    addressLabel(address),
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.grey900,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
