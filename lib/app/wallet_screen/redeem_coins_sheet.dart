import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';

class RedeemCoinsSheet extends StatefulWidget {
  const RedeemCoinsSheet({
    super.key,
    required this.currentCoins,
    required this.onRedeemed,
  });
  final int currentCoins;
  final VoidCallback onRedeemed;

  @override
  State<RedeemCoinsSheet> createState() => _RedeemCoinsSheetState();
}

class _RedeemCoinsSheetState extends State<RedeemCoinsSheet> {
  late TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: Constant.minRedeemCoins.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _enteredCoins => int.tryParse(_controller.text.trim()) ?? 0;
  double get _rupees => WalletProvider.coinsToRupees(_enteredCoins);

  /// Max coins allowed by daily redeem cap (₹). Capped by user's balance.
  int get _maxRedeemableCoins {
    if (Constant.coinsPer100Rupees <= 0) return widget.currentCoins;
    final capCoins = (Constant.dailyRedeemCapRupees / 100.0 * Constant.coinsPer100Rupees).floor();
    if (capCoins <= 0) return widget.currentCoins;
    return capCoins < widget.currentCoins ? capCoins : widget.currentCoins;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewPadding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppThemeData.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Redeem coins'.tr,
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              fontSize: 20,
              color: AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Min ${Constant.minRedeemCoins} coins. ${Constant.coinsPer100Rupees} coins = ₹100. Daily cap: ${Constant.amountShow(amount: Constant.dailyRedeemCapRupees.toStringAsFixed(0))}.'.tr,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              fontSize: 14,
              color: AppThemeData.grey600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Coins'.tr,
              hintText: '${Constant.minRedeemCoins}–$_maxRedeemableCoins',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed != null && parsed > _maxRedeemableCoins) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.text = _maxRedeemableCoins.toString();
                  _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                  setState(() {});
                });
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Text(
            '≈ ${Constant.amountShow(amount: _rupees.toStringAsFixed(2))}'.tr,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              fontSize: 14,
              color: AppThemeData.primary300,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_loading || _enteredCoins < Constant.minRedeemCoins || _enteredCoins > _maxRedeemableCoins)
                  ? null
                  : _redeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary300,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Redeem'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeem() async {
    // Enforce daily cap: never send more than allowed
    final coinsToRedeem = _enteredCoins.clamp(Constant.minRedeemCoins, _maxRedeemableCoins);
    setState(() => _loading = true);
    final wp = context.read<WalletProvider>();
    final err = await wp.redeemCoins(
      coins: coinsToRedeem,
      idempotencyKey: 'redeem_${DateTime.now().millisecondsSinceEpoch}',
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (err != null) {
      Get.snackbar('Redeem'.tr, err);
    } else {
      widget.onRedeemed();
      Get.back();
      Get.snackbar('Redeem'.tr, 'Coins redeemed successfully.'.tr);
    }
  }
}
