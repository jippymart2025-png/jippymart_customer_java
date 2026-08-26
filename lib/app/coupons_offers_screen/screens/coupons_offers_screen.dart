import 'package:flutter/material.dart';
import '../../Communityscreen/theme/app_theme.dart';
import '../providers/coupons_provider.dart';
import '../widgets/appbar.dart';
import '../widgets/bank_offer_card.dart';
import '../widgets/coupon_card.dart';
import '../widgets/coupon_search_bar.dart';
import '../widgets/free_delivery_banner.dart';
import '../widgets/more_offers_banner.dart';
import '../widgets/offer_category_tabs.dart';
import '../widgets/section_header.dart';

class CouponsOffersScreen extends StatefulWidget {
  const CouponsOffersScreen({super.key});

  @override
  State<CouponsOffersScreen> createState() => _CouponsOffersScreenState();
}

class _CouponsOffersScreenState extends State<CouponsOffersScreen> {
  late final CouponsController _controller;
  final TextEditingController _couponInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CouponsController();
  }

  @override
  void dispose() {
    _couponInputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applyCoupon(String code) {
    _controller.applyCoupon(code);
    _couponInputController.text = code;
    _showSnack('$code applied', success: true);
  }

  void _applyEnteredCoupon() {
    final code = _couponInputController.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter a coupon code', success: false);
      return;
    }
    _applyCoupon(code);
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(message),
            ],
          ),
          backgroundColor: success
              ? const Color(0xFF1F9254)
              : const Color(0xFF3A3D46),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            buildCouponsAppBar(context),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final showCoupons = _controller.showCouponSection;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CouponSearchBar(
            controller: _couponInputController,
            onApply: _applyEnteredCoupon,
          ),
          const SizedBox(height: 18),
          const FreeDeliveryBanner(progress: 0.82, remainingText: '₹101 more'),
          const SizedBox(height: 22),
          OfferCategoryTabs(
            selected: _controller.selectedCategory,
            onSelected: _controller.selectCategory,
          ),
          const SizedBox(height: 24),
          if (showCoupons) ...[
            const SectionHeader(
              title: 'Best Offers for You 🎉',
              subtitle: 'Pick the best offer and save more on your order',
            ),
            const SizedBox(height: 16),
            _buildCouponList(),
            const SizedBox(height: 22),
            const MoreOffersBanner(),
            const SizedBox(height: 30),
          ],
          const SectionHeader(
            title: 'Available Bank Offers',
            trailingLabel: 'View all',
          ),
          const SizedBox(height: 16),
          const BankOfferCard(
            bankName: 'HDFC BANK',
            offerTitle: '10% Instant Discount',
            offerSubtitle: 'On HDFC Credit & Debit Cards',
            saveText: 'Up to ₹150',
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList() {
    final coupons = _controller.filteredCoupons;

    if (coupons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 40,
                color: AppColors.textMuted.withOpacity(0.6),
              ),
              const SizedBox(height: 10),
              const Text(
                'No offers available',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different category',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView.separated(
        key: ValueKey(_controller.selectedCategory),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: coupons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return CouponCard(
            coupon: coupon,
            onApply: () => _applyCoupon(coupon.code),
          );
        },
      ),
    );
  }
}
