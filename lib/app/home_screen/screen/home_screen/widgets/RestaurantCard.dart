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

  bool _hasActiveDiscount(VendorModel vendor) {
    return vendor.offerName != null ||
        vendor.discountAmount != null ||
        vendor.couponCode != null ||
        vendor.promotionScheduleId != null;
  }

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
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image container with aspect ratio
                    AspectRatio(
                      aspectRatio: 1.5,
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

                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _RatingInfo(vendorModel: vendorModel),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.rectangle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: _VegInfo(isVeg: vendorModel.isveg),
                              ),
                            ),
                            // Status badge top-left
                            // Status badge top-left
                            // Offer badge bottom-left
                            if (_hasActiveDiscount(vendorModel))
                              Positioned(
                                left: 5,
                                bottom: 5,
                                child: _OfferBadge(vendorModel: vendorModel),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 14,
                            child: TimeThenFastDeliveryWidget(
                              deliveryTime: vendorModel.deliveryTime.toString(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        _DistanceInfo(vendorModel: vendorModel),
                      ],
                    ),
                    // const SizedBox(height: 4),
                    //
                    // // Rating + distance row
                    // _DistanceInfo(vendorModel: vendorModel),
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

class _OfferBadge extends StatelessWidget {
  final VendorModel vendorModel;

  const _OfferBadge({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    String text = 'OFFER';

    if (vendorModel.discountAmount != null) {
      if (vendorModel.priceType?.toUpperCase() == 'FLAT') {
        text = '₹${vendorModel.discountAmount!.toStringAsFixed(0)} OFF';
      } else {
        text = '${vendorModel.discountAmount!.toStringAsFixed(0)}% OFF';
      }
    } else if (vendorModel.offerName != null &&
        vendorModel.offerName!.isNotEmpty) {
      text = vendorModel.offerName!;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded, size: 12, color: Colors.red),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.red,
                fontSize: kFontXS,
                fontFamily: AppThemeData.bold,
                height: 1,
              ),
            ),
          ),
        ],
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

class _VegInfo extends StatelessWidget {
  final bool isVeg;

  const _VegInfo({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isVeg ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomInfoRow  — refined with consistent icon sizing
// ─────────────────────────────────────────────────────────────────────────────
class _RatingInfo extends StatelessWidget {
  final VendorModel vendorModel;

  const _RatingInfo({required this.vendorModel});

  String get _ratingText {
    return vendorModel.review?.toString() ?? '4.0';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 12,
          color: AppThemeData.kAccentAmber,
        ),
        const SizedBox(width: 3),
        Text(
          _ratingText,
          style: const TextStyle(
            fontSize: kFontXS + 1,
            fontFamily: AppThemeData.semiBold,
            color: Color(0xFF555570),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DistanceInfo extends StatelessWidget {
  final VendorModel vendorModel;

  const _DistanceInfo({required this.vendorModel});

  String get _distanceText {
    final distance = vendorModel.distanceKm;

    if (distance != null && distance >= 0) {
      return '${distance.toStringAsFixed(1)} ${Constant.distanceType}';
    }

    return '${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.near_me_rounded, size: 11, color: AppThemeData.grey400),
        const SizedBox(width: 2),
        Text(
          _distanceText,
          style: const TextStyle(
            fontSize: kFontXS + 1,
            fontFamily: AppThemeData.medium,
            color: Color(0xFF888899),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  const TimeThenFastDeliveryWidget({super.key, required this.deliveryTime});

  @override
  State<TimeThenFastDeliveryWidget> createState() =>
      TimeThenFastDeliveryWidgetState();
}

class TimeThenFastDeliveryWidgetState
    extends State<TimeThenFastDeliveryWidget> {
  bool _showFastDelivery = false;
  Timer? _timer;

  static const Duration _switchDuration = Duration(seconds: 4);
  static const Duration _animDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(_switchDuration, (_) {
      if (!mounted) return;

      setState(() {
        _showFastDelivery = !_showFastDelivery;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: _animDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _showFastDelivery ? _fastDeliveryRow : _timeText,
      ),
    );
  }

  Widget get _fastDeliveryRow {
    return Row(
      key: const ValueKey<String>('fast'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.electric_bolt_rounded,
          size: 10,
          color: ZColors.kGradStart,
        ),
        const SizedBox(width: 2),
        Text(
          'Fast delivery',
          style: const TextStyle(
            fontSize: kFontXS + 1,
            fontFamily: AppThemeData.semiBold,
            color: ZColors.kGradStart,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget get _timeText {
    return Row(
      key: const ValueKey<String>('time'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: 10, color: AppThemeData.grey500),
        const SizedBox(width: 2),
        Text(
          widget.deliveryTime,
          style: TextStyle(
            fontSize: kFontXS + 1,
            fontFamily: AppThemeData.medium,
            color: AppThemeData.grey500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
