import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/cart_screen/screens/order_placing_screen/provider/order_placing_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORDER PLACING SCREEN — redesigned
// States: loading → placing (animated countdown) → placed (success + order ID)
// ─────────────────────────────────────────────────────────────────────────────

class OrderPlacingScreen extends StatefulWidget {
  const OrderPlacingScreen({super.key});

  @override
  State<OrderPlacingScreen> createState() => _OrderPlacingScreenState();
}

class _OrderPlacingScreenState extends State<OrderPlacingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    // After order placed: sync wallet balance
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final wp = context.read<WalletProvider>();
        final cart = context.read<CartControllerProvider>();
        await wp.refreshWallet(force: true);
        if (!mounted) return;
        cart.syncWalletBalanceFromWallet(wp.moneyBalanceRupees);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _triggerSuccessAnim() {
    _pulseController.stop();
    _successController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<CartControllerProvider, OrderPlacingProvider>(
        builder: (context, cartController, controller, _) {
          final isPlaced =
              controller.isPlacing ||
              (controller.orderModel.id != null &&
                  controller.orderModel.id.toString().isNotEmpty);

          if (isPlaced &&
              !_successController.isAnimating &&
              _successController.value == 0) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _triggerSuccessAnim(),
            );
          }

          return WillPopScope(
            onWillPop: () async {
              cartController.forceRefreshCart();
              return true;
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: isPlaced
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black54,
                          size: 18,
                        ),
                        onPressed: () {
                          cartController.forceRefreshCart();
                          Get.back();
                        },
                      ),
              ),
              body: controller.isLoading
                  ? _buildLoading()
                  : isPlaced
                  ? _buildOrderPlaced(controller, context)
                  : _buildPlacing(controller),
              bottomNavigationBar: isPlaced
                  ? _buildTrackOrderBar(context, controller)
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ─── LOADING STATE ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppThemeData.primary300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Preparing your order...',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.medium,
              color: AppThemeData.grey500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PLACING STATE (animated) ─────────────────────────────────────────────

  Widget _buildPlacing(OrderPlacingProvider controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing icon
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppThemeData.primary50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_outlined,
                size: 48,
                color: AppThemeData.primary300,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Placing your order',
            style: TextStyle(
              fontSize: 26,
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Text(
            'Hang tight while we confirm everything with the restaurant.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: AppThemeData.grey100,
              color: AppThemeData.primary300,
              minHeight: 4,
            ),
          ),

          const SizedBox(height: 40),

          // Delivery address summary card
          if (controller.orderModel.address != null)
            _InfoCard(
              icon: Icons.location_on_outlined,
              iconColor: AppThemeData.primary300,
              title: 'Delivering to',
              value: controller.orderModel.address!.getFullAddress(),
            ),
        ],
      ),
    );
  }

  // ─── ORDER PLACED (success) ───────────────────────────────────────────────

  Widget _buildOrderPlaced(
    OrderPlacingProvider controller,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Animated success tick
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, child) =>
                Transform.scale(scale: _scaleAnim.value, child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 54,
                color: Color(0xFF388E3C),
              ),
            ),
          ),

          const SizedBox(height: 24),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  'Order Placed! 🎉',
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order is confirmed and being prepared.',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.regular,
                    color: AppThemeData.grey500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Order ID card
          FadeTransition(
            opacity: _fadeAnim,
            child: _InfoCard(
              icon: Icons.receipt_long_outlined,
              iconColor: AppThemeData.primary300,
              title: 'Order ID',
              value: '#${controller.orderModel.id}',
              valueStyle: TextStyle(
                fontSize: 15,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.primary300,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Order summary card
          if (controller.orderModel.products != null &&
              controller.orderModel.products!.isNotEmpty)
            FadeTransition(
              opacity: _fadeAnim,
              child: _buildOrderSummaryCard(controller),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(OrderPlacingProvider controller) {
    final products = controller.orderModel.products!;
    final shown = products.take(3).toList();
    final extra = products.length - 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeData.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeData.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: AppThemeData.grey500,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...shown.map((p) => _OrderItemRow(product: p)),
          if (extra > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+ $extra more item${extra > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── TRACK ORDER BOTTOM BAR ───────────────────────────────────────────────

  Widget _buildTrackOrderBar(
    BuildContext context,
    OrderPlacingProvider controller,
  ) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Consumer2<OrderProvider, DashBoardProvider>(
      builder: (context, orderProvider, dashBoardProvider, _) {
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
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottom),
          child: GestureDetector(
            onTap: () async {
              await orderProvider.getOrder(forceRefresh: true);
              dashBoardProvider.selectedIndex = 3;
              dashBoardProvider.notifyListeners();
              Get.offAll(() => const DashBoardScreen());
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppThemeData.primary300,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeData.primary300.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Track My Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── REUSABLE INFO CARD ───────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeData.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeData.grey100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppThemeData.regular,
                    color: AppThemeData.grey500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style:
                      valueStyle ??
                      TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey800,
                        height: 1.4,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ORDER ITEM ROW ───────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.product});

  final CartProductModel product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppThemeData.grey300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${product.quantity}x',
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppThemeData.medium,
              color: AppThemeData.grey500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              product.name ?? '',
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.regular,
                color: AppThemeData.grey800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
