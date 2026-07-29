import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../models/user_model.dart';
import '../../../../themes/app_them_data.dart';
import 'AddressTypeBadge.dart';

class AddressCard extends StatelessWidget {
  final ShippingAddress address;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const AddressCard({
    required this.address,
    required this.onTap,
    required this.onAction,
  });

  bool get _isDefault => address.isDefault == true;

  String get _label {
    final raw = address.addressAs?.trim();
    return (raw == null || raw.isEmpty) ? "Saved address".tr : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.rXL),
        child: Ink(
          decoration: BoxDecoration(
            color: Tokens.card,
            borderRadius: BorderRadius.circular(Tokens.rXL),
            border: Border.all(
              color: _isDefault ? Tokens.selectedBorder : Tokens.cardBorder,
              width: _isDefault ? 1.5 : 1,
            ),
            boxShadow: Tokens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Tokens.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: icon + title + badge + menu ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AddressTypeBadge(type: address.addressAs),
                    const SizedBox(width: Tokens.sp12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _label,
                                  style: const TextStyle(
                                    fontSize: Tokens.textMD,
                                    color: Tokens.textPrimary,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isDefault) ...[
                                const SizedBox(width: Tokens.sp8),
                                DefaultBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: Tokens.sp6),
                          Text(
                            address.getFullAddress().toString(),
                            style: const TextStyle(
                              fontSize: Tokens.textSM,
                              height: 1.4,
                              color: Tokens.textMuted,
                              fontFamily: AppThemeData.regular,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Tokens.sp8),
                    // More-actions button
                    MoreButton(onTap: onAction),
                  ],
                ),

                // ── Divider ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Tokens.sp12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Tokens.cardBorder,
                  ),
                ),

                // ── Meta chips ──
                Wrap(
                  spacing: Tokens.sp8,
                  runSpacing: Tokens.sp8,
                  children: [
                    if ((address.landmark ?? '').trim().isNotEmpty)
                      MetaChip(
                        icon: Icons.place_outlined,
                        label: address.landmark!.trim(),
                      ),
                    MetaChip(
                      icon: _isDefault
                          ? Icons.verified_rounded
                          : Icons.touch_app_rounded,
                      label: _isDefault
                          ? "Primary address".tr
                          : "Tap to deliver here".tr,
                      highlighted: _isDefault,
                    ),
                    if (!_isDefault)
                      MetaChip(
                        icon: Icons.star_outline_rounded,
                        label: "Set as default".tr,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
