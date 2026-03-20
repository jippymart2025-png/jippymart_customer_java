import 'package:flutter_svg/svg.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dotted_border/src/dotted_border_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  bool _hasInitialized = false;
  final TextEditingController _couponCodeController = TextEditingController();
  static const String _fixPriceType = 'fix price';

  bool _isFixPriceDiscount(String? discountType) {
    return (discountType ?? '').trim().toLowerCase() == _fixPriceType;
  }

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      Future.microtask(() {
        if (mounted) {
          final controller = Provider.of<CartControllerProvider>(
            context,
            listen: false,
          );
          controller.ensureCouponsLoaded();
        }
      });
    }
  }

  void _applyCoupon(CartControllerProvider controller, CouponModel coupon) {
    if (coupon.isEnabled == false) {
      ShowToastDialog.showToast('You have already used this coupon'.tr);
      return;
    }
    final enteredCode = _couponCodeController.text.trim().toLowerCase();
    final couponCode = coupon.code?.toLowerCase() ?? '';
    if (enteredCode.isNotEmpty && enteredCode != couponCode) {
      ShowToastDialog.showToast("Coupon code doesn't match".tr);
      return;
    }
    double minValue = double.tryParse(coupon.itemValue ?? '0') ?? 0.0;
    if (controller.subTotal < minValue) {
      ShowToastDialog.showToast(
        'Apply on orders above ₹${minValue.toStringAsFixed(0)}',
      );
      return;
    }
    double couponAmount = Constant.calculateDiscount(
      amount: controller.subTotal.toString(),
      offerModel: coupon,
    );
    if (couponAmount >= controller.subTotal) {
      ShowToastDialog.showToast('Coupon discount cannot exceed order total'.tr);
      return;
    }
    controller.selectedCouponModel = coupon;
    controller.couponCodeController.text = coupon.code ?? '';
    controller.calculatePrice();
    ShowToastDialog.showToast('Coupon applied!'.tr);
    Get.back();
  }

  void _applyManualCoupon(CartControllerProvider controller) {
    final enteredCode = _couponCodeController.text.trim().toLowerCase();
    if (enteredCode.isEmpty) {
      ShowToastDialog.showToast('Please enter a coupon code'.tr);
      return;
    }
    final matchedCoupon = controller.allCouponList.firstWhere(
      (c) => (c.code ?? '').trim().toLowerCase() == enteredCode,
      orElse: CouponModel.new,
    );
    if ((matchedCoupon.id ?? '').isEmpty && (matchedCoupon.code ?? '').isEmpty) {
      ShowToastDialog.showToast('Invalid coupon code'.tr);
      return;
    }
    _applyCoupon(controller, matchedCoupon);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartControllerProvider>(
      builder: (context, controller, _) {
        final coupons = controller.couponList;
        final isLoading = controller.isLoadingCoupons;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Apply Coupon',
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 18,
                color: AppThemeData.grey900,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(isLoading ? 80 : 70),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Search / enter coupon field
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppThemeData.grey50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppThemeData.grey200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.confirmation_num_outlined,
                            color: AppThemeData.grey400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _couponCodeController,
                              enabled: !isLoading,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.medium,
                                color: AppThemeData.grey900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppThemeData.grey400,
                                  fontFamily: AppThemeData.regular,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => _applyManualCoupon(controller),
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppThemeData.primary300,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Apply',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppThemeData.primary300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading coupons...',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppThemeData.grey500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (coupons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${coupons.length} offer${coupons.length > 1 ? 's' : ''} available',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppThemeData.grey500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          body: isLoading && coupons.isEmpty
              ? _buildFullLoader()
              : coupons.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) =>
                      _buildCouponCard(controller, coupons[index]),
                ),
        );
      },
    );
  }

  Widget _buildCouponCard(
    CartControllerProvider controller,
    CouponModel coupon,
  ) {
    final isUsed = coupon.isEnabled == false;
    final isFixPrice = _isFixPriceDiscount(coupon.discountType);
    final discountText = (coupon.discount ?? '0').trim();
    final discountBadgeText = isFixPrice
        ? Constant.amountShow(amount: discountText)
        : '$discountText%';

    return GestureDetector(
      onTap: isUsed
          ? () => ShowToastDialog.showToast('Coupon already used'.tr)
          : () => _applyCoupon(controller, coupon),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Opacity(
          opacity: isUsed ? 0.6 : 1.0,
          child: Row(
            children: [
              // ── Left discount badge ────────────────────────────────────
              Container(
                width: 72,
                constraints: const BoxConstraints(minHeight: 90),
                decoration: BoxDecoration(
                  color: isUsed
                      ? AppThemeData.grey200
                      : AppThemeData.primary300,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUsed ? 'USED' : discountBadgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isUsed && !isFixPrice) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'OFF',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Notch
              CustomPaint(size: const Size(12, 90), painter: _NotchPainter()),

              // ── Right content ──────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Code chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppThemeData.primary200,
                                  style: isUsed
                                      ? BorderStyle.solid
                                      : BorderStyle.solid,
                                ),
                              ),
                              child: Text(
                                coupon.code ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: AppThemeData.semiBold,
                                  color: AppThemeData.primary300,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              coupon.description ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.regular,
                                color: AppThemeData.grey600,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (coupon.itemValue != null &&
                                coupon.itemValue != '0') ...[
                              const SizedBox(height: 4),
                              Text(
                                'Min order ₹${double.tryParse(coupon.itemValue ?? '0')?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: AppThemeData.regular,
                                  color: AppThemeData.grey400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Apply button / Used tag
                      if (isUsed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.grey100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Used',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.grey500,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.primary50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppThemeData.primary300),
                          ),
                          child: Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.primary300,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppThemeData.primary300),
          const SizedBox(height: 16),
          Text(
            'Finding best offers...',
            style: TextStyle(fontSize: 14, color: AppThemeData.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppThemeData.grey50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.confirmation_num_outlined,
              size: 36,
              color: AppThemeData.grey300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No coupons available',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for great deals',
            style: TextStyle(fontSize: 13, color: AppThemeData.grey400),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }
}

// ─── Notch painter for coupon card ───────────────────────────────────────────
class _NotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5F5F5);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.35)
      ..arcToPoint(
        Offset(size.width, size.height * 0.65),
        radius: const Radius.circular(12),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    // Dashed line
    final dashPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 4),
        dashPaint,
      );
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
