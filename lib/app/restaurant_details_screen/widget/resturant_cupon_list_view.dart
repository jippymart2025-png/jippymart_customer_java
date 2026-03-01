import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../constant/constant.dart';
import '../../../constant/show_toast_dialog.dart';

// Intentionally kept at file scope so the shimmer loader can be imported
// separately without bringing in the full widget tree.
Widget resturantDetailsShimmer() => const SizedBox.shrink();

class CouponListView extends StatelessWidget {
  final RestaurantDetailsProvider controller;

  const CouponListView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // ── Use LayoutBuilder so sizing reacts to the parent width, not the
    //    full screen width. This handles tablets, split-screens, and
    //    landscape mode correctly without a separate MediaQuery call. ──
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;

        // Card proportions that feel right across all screen sizes:
        //   • phone  (360 – 480 px) → card ≈ 62 % of available width
        //   • tablet (600 – 840 px) → card ≈ 45 % — show ~2 cards at once
        //   • large  (> 840 px)    → fixed 320 px max
        final cardWidth =
            (available *
                    (available < 480
                        ? 0.62
                        : available < 840
                        ? 0.45
                        : 0.35))
                .clamp(200.0, 320.0);

        // Card height scales with width but stays within a tight range
        final cardHeight = (cardWidth * 0.29).clamp(68.0, 88.0);

        // GIF/discount badge scales with card
        final gifSize = (cardHeight * 0.72).clamp(44.0, 62.0);

        // Typography scales with available width
        final titleSize = _lerp(available, 360, 840, 12.0, 15.0);
        final subSize = _lerp(available, 360, 840, 10.0, 12.5);

        return SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // ClampingScrollPhysics keeps horizontal swipe from competing
            // with the parent vertical scroll on heavy lists
            physics: const ClampingScrollPhysics(),
            itemCount: controller.couponList.length,
            itemBuilder: (context, index) {
              final coupon = controller.couponList[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < controller.couponList.length - 1 ? 10 : 0,
                ),
                child: _CouponCard(
                  coupon: coupon,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  gifSize: gifSize,
                  titleSize: titleSize,
                  subSize: subSize,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Linear interpolation helper — maps [inMin..inMax] → [outMin..outMax]
  static double _lerp(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
    return outMin + t * (outMax - outMin);
  }
}

// ── Extracted into its own StatelessWidget so ListView can keep each
//    card in the element tree without rebuilding siblings. ──
class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final double cardWidth;
  final double cardHeight;
  final double gifSize;
  final double titleSize;
  final double subSize;

  const _CouponCard({
    required this.coupon,
    required this.cardWidth,
    required this.cardHeight,
    required this.gifSize,
    required this.titleSize,
    required this.subSize,
  });

  @override
  Widget build(BuildContext context) {
    final isUsed = coupon.isEnabled == false;

    return RepaintBoundary(
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Material(
          color: AppThemeData.grey50,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isUsed ? null : () => _copyCode(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppThemeData.grey100, width: 1),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: (cardWidth * 0.04).clamp(6.0, 12.0),
                vertical: (cardHeight * 0.1).clamp(6.0, 10.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DiscountBadge(
                    coupon: coupon,
                    gifSize: gifSize,
                    labelSize: (gifSize * 0.22).clamp(9.0, 13.0),
                  ),
                  SizedBox(width: (cardWidth * 0.03).clamp(6.0, 10.0)),
                  Expanded(
                    child: _CouponInfo(
                      coupon: coupon,
                      isUsed: isUsed,
                      titleSize: titleSize,
                      subSize: subSize,
                      onCopy: () => _copyCode(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code.toString())).then((_) {
      ShowToastDialog.showToast("Copied".tr);
    });
  }
}

// ── Discount badge (gif background + amount/percent text) ──
class _DiscountBadge extends StatelessWidget {
  final CouponModel coupon;
  final double gifSize;
  final double labelSize;

  const _DiscountBadge({
    required this.coupon,
    required this.gifSize,
    required this.labelSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gifSize,
      height: gifSize,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/offer_gif.gif"),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: Text(
            coupon.discountType == "Fix Price"
                ? Constant.amountShow(amount: coupon.discount.toString())
                : "${coupon.discount}%",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemeData.grey50,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
              fontSize: labelSize,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Text section: description + code/expiry or "Used" ──
class _CouponInfo extends StatelessWidget {
  final CouponModel coupon;
  final bool isUsed;
  final double titleSize;
  final double subSize;
  final VoidCallback onCopy;

  const _CouponInfo({
    required this.coupon,
    required this.isUsed,
    required this.titleSize,
    required this.subSize,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Description
        Text(
          coupon.description ?? "Discount Coupon",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: titleSize,
            color: AppThemeData.grey900,
            fontFamily: AppThemeData.semiBold,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        // Used badge OR code + expiry row
        if (isUsed)
          _UsedBadge(subSize: subSize)
        else
          _CodeExpiryRow(coupon: coupon, subSize: subSize, onCopy: onCopy),
      ],
    );
  }
}

class _UsedBadge extends StatelessWidget {
  final double subSize;

  const _UsedBadge({required this.subSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppThemeData.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "Used",
        style: TextStyle(
          fontFamily: AppThemeData.medium,
          color: AppThemeData.grey500,
          fontSize: subSize,
        ),
      ),
    );
  }
}

class _CodeExpiryRow extends StatelessWidget {
  final CouponModel coupon;
  final double subSize;
  final VoidCallback onCopy;

  const _CodeExpiryRow({
    required this.coupon,
    required this.subSize,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Coupon code
        Flexible(
          child: Text(
            coupon.code.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: subSize,
              color: AppThemeData.primary300,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Copy icon — tappable
        GestureDetector(
          onTap: onCopy,
          child: SvgPicture.asset(
            "assets/icons/ic_copy.svg",
            width: (subSize * 1.2).clamp(12.0, 16.0),
            height: (subSize * 1.2).clamp(12.0, 16.0),
            colorFilter: ColorFilter.mode(
              AppThemeData.primary300,
              BlendMode.srcIn,
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Expiry date
        Flexible(
          child: Text(
            _formatExpiryDate(coupon.expiresAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: subSize,
              color: AppThemeData.grey400,
              fontFamily: AppThemeData.medium,
            ),
          ),
        ),
      ],
    );
  }

  String _formatExpiryDate(dynamic expiresAt) {
    if (expiresAt == null) return "No expiry";
    try {
      final date = expiresAt is DateTime
          ? expiresAt
          : DateTime.parse(expiresAt.toString());
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return expiresAt.toString();
    }
  }
}
