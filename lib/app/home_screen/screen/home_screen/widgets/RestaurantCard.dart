import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../../constant/constant.dart';
import '../../../../../models/vendor_model.dart';
import '../../../../../themes/app_them_data.dart';
import '../../../../../themes/responsive.dart';
import '../../../../../utils/restaurant_status_utils.dart';
import '../../../../../widget/restaurant_image_with_status.dart';
import '../../../../restaurant_details_screen/provider/restaurant_details_provider.dart';
import '../../../../restaurant_details_screen/restaurant_details_screen.dart';

class RestaurantCard extends StatelessWidget {
  final VendorModel vendorModel;

  const RestaurantCard({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    final rdp = context.read<RestaurantDetailsProvider>();
    final isClosed = !RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isClosed
            ? null
            : () {
                rdp.initFunction(vendorModels: vendorModel);
                Get.to(() => const RestaurantDetailsScreen());
              },
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: Ink(
          decoration: BoxDecoration(
            color: AppThemeData.grey50,
            borderRadius: BorderRadius.circular(kRadiusMD),
            boxShadow: const [
              BoxShadow(
                color: AppThemeData.kCardShadow,
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image container with aspect ratio
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadiusSM + 2),
                          color: const Color(0xFFF0F0F0),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                kRadiusSM + 2,
                              ),
                              child: RestaurantImageWithStatus(
                                vendorModel: vendorModel,
                                height: double.infinity,
                                width: double.infinity,
                              ),
                            ),
                            // Status badge top-left
                            Positioned(
                              top: 5,
                              left: 5,
                              child: _StatusBadge(vendorModel: vendorModel),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Restaurant name
                    Text(
                      vendorModel.title ?? 'Restaurant',
                      style: const TextStyle(
                        fontSize: kFontMD,
                        fontFamily: AppThemeData.semiBold,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Delivery time / fast delivery toggle
                    SizedBox(
                      height: 14,
                      child: TimeThenFastDeliveryWidget(
                        deliveryTime: Constant.getDeliveryTimeText(vendorModel),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Rating + distance row
                    _BottomInfoRow(vendorModel: vendorModel),
                  ],
                ),
              ),

              // Closed overlay
              if (isClosed) const _ClosedOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClosedOverlay  — refined frosted-glass look
// ─────────────────────────────────────────────────────────────────────────────

class _ClosedOverlay extends StatelessWidget {
  const _ClosedOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.38),
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CLOSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: kFontXS + 1,
                fontFamily: AppThemeData.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge  — sharper pill badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final VendorModel vendorModel;

  const _StatusBadge({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);
    final bgColor = isOpen
        ? AppThemeData.kOpenGreen.withOpacity(0.92)
        : AppThemeData.kClosedRed.withOpacity(0.92);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: kFontXS,
              fontFamily: AppThemeData.bold,
              height: 1,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomInfoRow  — refined with consistent icon sizing
// ─────────────────────────────────────────────────────────────────────────────
class _BottomInfoRow extends StatelessWidget {
  final VendorModel vendorModel;

  const _BottomInfoRow({required this.vendorModel});

  String get _distanceText {
    if (vendorModel.distance != null && vendorModel.distance! > 0) {
      return '${vendorModel.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
    }
    return '${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}';
  }

  String get _ratingText => Constant.calculateReview(
    reviewCount: vendorModel.reviewsCount.toString(),
    reviewSum: vendorModel.reviewsSum.toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rating
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 11,
                color: AppThemeData.kAccentAmber,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _ratingText,
                  style: const TextStyle(
                    fontSize: kFontXS + 1,
                    fontFamily: AppThemeData.semiBold,
                    color: Color(0xFF555570),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Dot separator
        Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Color(0xFFCCCCCC),
            shape: BoxShape.circle,
          ),
        ),

        // Distance
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 10,
                color: AppThemeData.grey400,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _distanceText,
                  style: const TextStyle(
                    fontSize: kFontXS,
                    fontFamily: AppThemeData.medium,
                    color: Color(0xFF888899),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimeThenFastDeliveryWidget  — refined with better icon & colours
// ─────────────────────────────────────────────────────────────────────────────

class TimeThenFastDeliveryWidget extends StatefulWidget {
  final String deliveryTime;

  const TimeThenFastDeliveryWidget({required this.deliveryTime});

  @override
  State<TimeThenFastDeliveryWidget> createState() =>
      TimeThenFastDeliveryWidgetState();
}

class TimeThenFastDeliveryWidgetState
    extends State<TimeThenFastDeliveryWidget> {
  bool _showFastDelivery = false;
  Timer? _timer;

  static const _switchDuration = Duration(seconds: 4);
  static const _animDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_switchDuration, (_) {
      if (mounted) setState(() => _showFastDelivery = !_showFastDelivery);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: _animDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _showFastDelivery ? _fastDeliveryRow : _timeText,
      ),
    );
  }

  Widget get _fastDeliveryRow => Row(
    key: const ValueKey<String>('fast'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.electric_bolt_rounded,
        size: 10,
        color: ZColors.kGradStart,
      ),
      const SizedBox(width: 2),
      Expanded(
        child: Text(
          'Fast delivery',
          style: const TextStyle(
            fontSize: kFontXS + 1,
            fontFamily: AppThemeData.semiBold,
            color: ZColors.kGradStart,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget get _timeText => Row(
    key: const ValueKey<String>('time'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.access_time_rounded, size: 10, color: AppThemeData.grey500),
      const SizedBox(width: 2),
      Expanded(
        child: Text(
          widget.deliveryTime,
          style: TextStyle(
            fontSize: kFontXS + 1,
            fontFamily: AppThemeData.medium,
            color: AppThemeData.grey500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
