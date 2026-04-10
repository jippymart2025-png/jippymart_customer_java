import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT SCREEN — clear step-by-step layout
// Step 1: optionally use wallet  |  Step 2: pick payment method  |  Pay CTA
// ─────────────────────────────────────────────────────────────────────────────

class SelectPaymentScreen extends StatefulWidget {
  const SelectPaymentScreen({super.key});

  @override
  State<SelectPaymentScreen> createState() => _SelectPaymentScreenState();
}

class _SelectPaymentScreenState extends State<SelectPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: _buildAppBar(),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderSummaryStrip(controller: controller),
                  if (controller.selectedFoodType != 'TakeAway') ...[
                    const SizedBox(height: 16),
                    _DeliveryAddressCard(controller: controller),
                  ],
                  const SizedBox(height: 20),
                  _sectionLabel('STEP 1  ·  Your Wallet'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _WalletToggleCard(controller: controller),
                  ),
                  if (!controller.isFullyPaidByWallet) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('STEP 2  ·  Pay Remaining via'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _PaymentMethodsCard(controller: controller),
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _ConfirmPayBar(controller: controller),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.black87,
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Payment',
        style: TextStyle(
          fontSize: 18,
          fontFamily: AppThemeData.semiBold,
          color: AppThemeData.grey900,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppThemeData.grey100),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontFamily: AppThemeData.semiBold,
          color: AppThemeData.grey500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── ORDER SUMMARY STRIP ─────────────────────────────────────────────────────

class _OrderSummaryStrip extends StatelessWidget {
  const _OrderSummaryStrip({required this.controller});

  final CartControllerProvider controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemeData.grey500,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Constant.amountShow(
                    amount: controller.totalAmount.toStringAsFixed(2),
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppThemeData.grey100),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Items',
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemeData.grey500,
                  fontFamily: AppThemeData.regular,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${HomeProvider.cartItem.length}',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── DELIVERY ADDRESS (like checkout screen) ─────────────────────────────────

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.controller});

  final CartControllerProvider controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              controller.changeLocationFunctionInCart(context: context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppThemeData.primary300,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Delivering to',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.regular,
                              color: AppThemeData.grey500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              controller.selectedAddress?.addressAs
                                      ?.toString() ??
                                  'Home',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.selectedAddress?.getFullAddress() ??
                            'Select delivery address',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.grey800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.primary300,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: AppThemeData.primary300,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WALLET TOGGLE CARD ───────────────────────────────────────────────────────

class _WalletToggleCard extends StatelessWidget {
  const _WalletToggleCard({required this.controller});

  final CartControllerProvider controller;

  @override
  Widget build(BuildContext context) {
    final balance = controller.walletBalanceRupees;
    final hasBalance = balance > 0;
    final walletDisabledByPromos = controller.isWalletDisabledByPromotions;
    final canUseWallet = hasBalance && !walletDisabledByPromos;
    final isUsing = controller.useWalletBalance && canUseWallet;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUsing
              ? AppThemeData.primary300.withOpacity(0.5)
              : AppThemeData.grey200,
          width: isUsing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUsing
                ? AppThemeData.primary300.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isUsing
                        ? AppThemeData.primary300
                        : AppThemeData.grey100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isUsing ? Colors.white : AppThemeData.grey400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JippyMart Wallet',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.semiBold,
                          color: hasBalance
                              ? AppThemeData.grey900
                              : AppThemeData.grey400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        walletDisabledByPromos
                            ? 'Not available for promotional items'
                            : hasBalance
                            ? 'Balance: ${Constant.amountShow(amount: balance.toStringAsFixed(2))}'
                            : 'No balance available',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: walletDisabledByPromos
                              ? AppThemeData.grey500
                              : hasBalance
                              ? AppThemeData.primary300
                              : AppThemeData.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isUsing,
                  onChanged: canUseWallet
                      ? (v) async => await controller.setUseWalletBalance(v)
                      : null,
                  activeColor: AppThemeData.primary300,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          if (isUsing)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppThemeData.primary50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                child: controller.isFullyPaidByWallet
                    ? Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF43A047),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Wallet covers the full amount — no extra payment needed!',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: AppThemeData.medium,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppThemeData.primary300,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: AppThemeData.regular,
                                  color: AppThemeData.grey700,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: Constant.amountShow(
                                      amount: controller.walletToUse
                                          .toStringAsFixed(2),
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      color: AppThemeData.primary300,
                                    ),
                                  ),
                                  const TextSpan(text: ' from wallet  +  '),
                                  TextSpan(
                                    text: Constant.amountShow(
                                      amount: controller.paymentGatewayAmount
                                          .toStringAsFixed(2),
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      color: AppThemeData.grey900,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' via payment method below',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── PAYMENT METHODS CARD ─────────────────────────────────────────────────────

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({required this.controller});

  final CartControllerProvider controller;

  bool get _isCodEnabledByZone => controller.isCodEnabledForCurrentZone;

  bool get _isCodVisible {
    final amt = controller.useWalletBalance
        ? controller.amountToChargeViaGateway
        : controller.subTotal;
    return _isCodEnabledByZone &&
        amt <= controller.codMaxAmountForCurrentZone &&
        !controller.hasPromotionalItems();
  }

  bool get _showCodDisabledByZone => !_isCodEnabledByZone;

  bool get _showCodMaxMsg {
    final amt = controller.useWalletBalance
        ? controller.amountToChargeViaGateway
        : controller.subTotal;
    return _isCodEnabledByZone &&
        amt > controller.codMaxAmountForCurrentZone;
  }

  bool get _showCodPromoMsg {
    final amt = controller.useWalletBalance
        ? controller.amountToChargeViaGateway
        : controller.subTotal;
    return _isCodEnabledByZone &&
        amt <= controller.codMaxAmountForCurrentZone &&
        controller.hasPromotionalItems();
  }

  bool get _hasOnline => controller.isRazorpayEnabledForCurrentZone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isCodVisible || _showCodDisabledByZone)
            _PaymentTile(
              controller: controller,
              value: PaymentGateway.cod,
              icon: Icons.payments_outlined,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF388E3C),
              title: 'Cash on Delivery',
              subtitle: _showCodDisabledByZone
                  ? 'Disabled for your delivery zone'
                  : 'Pay in cash when order arrives',
              roundTop: true,
              roundBottom: !_hasOnline,
              showDivider: _hasOnline,
              isEnabled: !_showCodDisabledByZone,
            ),
          if (_showCodMaxMsg)
            _WarningBanner(
              message:
                  'COD not available for orders above ₹${controller.codMaxAmountForCurrentZone.toStringAsFixed(0)}',
            ),
          if (_showCodPromoMsg)
            const _WarningBanner(
              message: 'COD unavailable for promotional items',
            ),
          if (_hasOnline) ...[
            _PaymentTile(
              controller: controller,
              value: PaymentGateway.paytm,
              icon: Icons.account_balance_wallet_rounded,
              iconBgColor: const Color(0xFFE8EAF6),
              iconColor: const Color(0xFF3F51B5),
              title: 'Pay via Paytm',
              subtitle: 'UPI · Wallet · Cards',
              roundTop: !_isCodVisible,
              roundBottom: false,
              showDivider: true,
            ),
            _PaymentTile(
              controller: controller,
              value: PaymentGateway.razorpay,
              icon: Icons.credit_card_rounded,
              iconBgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
              title: 'Pay Online (Razorpay)',
              subtitle: 'UPI · Cards · Net Banking',
              roundTop: false,
              roundBottom: true,
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.controller,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.roundTop,
    required this.roundBottom,
    required this.showDivider,
    this.isEnabled = true,
  });

  final CartControllerProvider controller;
  final PaymentGateway value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool roundTop;
  final bool roundBottom;
  final bool showDivider;
  final bool isEnabled;

  bool get _selected => controller.selectedPaymentMethod == value.name;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: roundTop ? const Radius.circular(14) : Radius.zero,
      bottom: roundBottom ? const Radius.circular(14) : Radius.zero,
    );
    return Column(
      children: [
        InkWell(
          borderRadius: radius,
          onTap: isEnabled
              ? () => controller.setSelectedPaymentMethod(value.name)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _selected && isEnabled
                  ? AppThemeData.primary50
                  : Colors.transparent,
              borderRadius: radius,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isEnabled ? iconBgColor : AppThemeData.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? iconColor : AppThemeData.grey400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.semiBold,
                          color:
                              isEnabled ? AppThemeData.grey900 : AppThemeData.grey400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.regular,
                          color:
                              isEnabled ? AppThemeData.grey500 : AppThemeData.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selected && isEnabled
                        ? AppThemeData.primary300
                        : Colors.transparent,
                    border: Border.all(
                      color: _selected && isEnabled
                          ? AppThemeData.primary300
                          : (isEnabled
                              ? AppThemeData.grey300
                              : AppThemeData.grey200),
                      width: 2,
                    ),
                  ),
                  child: _selected && isEnabled
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppThemeData.grey100,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CONFIRM PAY BAR ─────────────────────────────────────────────────────────

class _ConfirmPayBar extends StatefulWidget {
  const _ConfirmPayBar({required this.controller});

  final CartControllerProvider controller;

  @override
  State<_ConfirmPayBar> createState() => _ConfirmPayBarState();
}

class _ConfirmPayBarState extends State<_ConfirmPayBar> {
  bool _tapLocked = false;
  String _lastPaymentConfigKey = '';

  CartControllerProvider get controller => widget.controller;

  String get _btnLabel {
    if (controller.isFullyPaidByWallet) {
      return 'Pay ${Constant.amountShow(amount: controller.totalAmount.toStringAsFixed(2))} from Wallet';
    }
    if (controller.useWalletBalance && controller.walletToUse > 0) {
      return 'Confirm & Pay ${Constant.amountShow(amount: controller.paymentGatewayAmount.toStringAsFixed(2))}';
    }
    return 'Confirm & Pay ${Constant.amountShow(amount: controller.totalAmount.toStringAsFixed(2))}';
  }

  bool get isCod => controller.selectedPaymentMethod == PaymentGateway.cod.name;

  bool get _canPay =>
      controller.isFullyPaidByWallet ||
      controller.selectedPaymentMethod.isNotEmpty;

  String _paymentConfigKey() {
    return [
      controller.selectedPaymentMethod,
      controller.useWalletBalance.toString(),
      controller.walletToUse.toStringAsFixed(2),
      controller.isFullyPaidByWallet.toString(),
      controller.paymentGatewayAmount.toStringAsFixed(2),
      controller.totalAmount.toStringAsFixed(2),
    ].join('|');
  }

  void _syncTapLockWithPaymentConfig() {
    final currentKey = _paymentConfigKey();
    if (_lastPaymentConfigKey.isEmpty) {
      _lastPaymentConfigKey = currentKey;
      return;
    }

    // Unlock only when user changes payment setup.
    if (currentKey != _lastPaymentConfigKey) {
      _tapLocked = false;
      _lastPaymentConfigKey = currentKey;
    }
  }

  Future<void> _handleConfirmPay(
    BuildContext context,
    CartControllerProvider controller,
  ) async {
    if (_tapLocked || _isProcessing) return;
    setState(() {
      _tapLocked = true;
      _lastPaymentConfigKey = _paymentConfigKey();
    });

    try {
      if (controller.isFullyPaidByWallet) {
        controller.setSelectedPaymentMethod(PaymentGateway.wallet.name);
        await controller.placeOrder(context);
        // Do not Get.back() here: on success, placeOrder → setOrder already
        // navigates with Get.off(OrderPlacingScreen). Popping would close the order-placed screen.
        return;
      }
      controller.startOrderProcessing();
      controller.providerInitializer(context: context);
      await controller.processPayment(controller, context);
      // Do not pop this screen after starting a gateway flow.
      // Success path navigates to OrderPlacingScreen; popping here can cause route jank/races.
    } catch (e) {
      controller.endOrderProcessing();
      if (context.mounted) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('An error occurred. Please try again.'.tr);
      }
    }
  }

  bool get _isProcessing => controller.isProcessingOrder;

  @override
  Widget build(BuildContext context) {
    _syncTapLockWithPaymentConfig();
    final bottom = MediaQuery.of(context).padding.bottom;
    final showSplit =
        controller.useWalletBalance &&
        controller.walletToUse > 0 &&
        !controller.isFullyPaidByWallet;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSplit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SplitChip(
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppThemeData.primary300,
                  amount: Constant.amountShow(
                    amount: controller.walletToUse.toStringAsFixed(2),
                  ),
                  label: 'Wallet',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '+',
                    style: TextStyle(fontSize: 18, color: AppThemeData.grey400),
                  ),
                ),

                _SplitChip(
                  icon: isCod
                      ? Icons.payments_outlined
                      : Icons.credit_card_rounded,
                  color: isCod
                      ? const Color(0xFF388E3C)
                      : const Color(0xFF1565C0),
                  amount: Constant.amountShow(
                    amount: controller.paymentGatewayAmount.toStringAsFixed(2),
                  ),
                  label: isCod ? 'COD' : 'Online',
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(
              onPressed: (_canPay && !_isProcessing && !_tapLocked)
                  ? () async => _handleConfirmPay(context, controller)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeData.primary300,
                disabledBackgroundColor: AppThemeData.grey200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith<double>(
                  (states) =>
                      states.contains(WidgetState.disabled) ? 0 : 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else
                    Icon(
                      _canPay
                          ? Icons.lock_outline_rounded
                          : Icons.lock_open_outlined,
                      color: _canPay ? Colors.white70 : AppThemeData.grey400,
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isProcessing
                          ? 'Processing...'
                          : (_tapLocked && _canPay)
                          ? 'Payment started - change method to retry'
                          : (_canPay
                                ? _btnLabel
                                : 'Select a payment method'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: (_canPay || _isProcessing)
                            ? Colors.white
                            : AppThemeData.grey400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_canPay) ...[
            const SizedBox(height: 8),
            Text(
              'Choose Cash on Delivery or Online Payment above',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppThemeData.grey400),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitChip extends StatelessWidget {
  const _SplitChip({
    required this.icon,
    required this.color,
    required this.amount,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String amount;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
