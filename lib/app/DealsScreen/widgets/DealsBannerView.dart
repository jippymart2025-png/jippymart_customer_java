import 'dart:async';

import 'package:flutter/material.dart';

import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';

/// Fallback gradient configs for banners without a valid photo.
const List<List<Color>> _kBannerGradients = [
  [Color(0xFFD12477), Color(0xFF8E1552)],
  [Color(0xFF6C3BE4), Color(0xFF3B0FA8)],
  [Color(0xFFFF6B35), Color(0xFFD12477)],
  [Color(0xFF00B4D8), Color(0xFF0077B6)],
  [Color(0xFF2D6A4F), Color(0xFF1B4332)],
];

/// Auto-playing banner carousel with dot indicators, shown at the
/// top of the Deals screen.
class DealsBannerView extends StatefulWidget {
  const DealsBannerView({
    super.key,
    required this.banners,
    this.autoPlay = true,
  });

  final List<BannerModel> banners;
  final bool autoPlay;

  @override
  State<DealsBannerView> createState() => _DealsBannerViewState();
}

class _DealsBannerViewState extends State<DealsBannerView>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _indicatorAnim;
  Timer? _timer;
  int _currentPage = 0;
  bool _animating = false;

  static const Duration _interval = Duration(seconds: 4);
  static const Duration _animDuration = Duration(milliseconds: 480);

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 1.0);
    _indicatorAnim = AnimationController(vsync: this, duration: _interval);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPlay && widget.banners.length > 1) {
        _startTimer();
        _indicatorAnim.forward();
      }
    });
  }

  @override
  void didUpdateWidget(DealsBannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length &&
        widget.banners.length > 1 &&
        widget.autoPlay) {
      _stopTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _pageCtrl.dispose();
    _indicatorAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.banners.length <= 1 || !widget.autoPlay) return;
    if (!_pageCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _pageCtrl.hasClients) _startTimer();
      });
      return;
    }
    _indicatorAnim
      ..reset()
      ..forward();
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_pageCtrl.hasClients || _animating) return;
      if (widget.banners.length <= 1) return;
      final next = (_currentPage + 1) % widget.banners.length;
      _animating = true;
      _pageCtrl
          .animateToPage(
            next,
            duration: _animDuration,
            curve: Curves.easeInOutCubic,
          )
          .then((_) => _animating = false);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _indicatorAnim.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 175,
            child: GestureDetector(
              onPanStart: (_) => _stopTimer(),
              onPanEnd: (_) {
                if (widget.autoPlay && widget.banners.length > 1) {
                  _startTimer();
                }
              },
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.banners.length,
                onPageChanged: (v) {
                  setState(() => _currentPage = v);
                  _indicatorAnim
                    ..reset()
                    ..forward();
                },
                itemBuilder: (ctx, i) {
                  final banner = widget.banners[i];
                  final gradColors =
                      _kBannerGradients[i % _kBannerGradients.length];
                  return _BannerCard(banner: banner, gradColors: gradColors);
                },
              ),
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final isActive = _currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? const Color(0xFFD12477)
                      : const Color(0xFFD8D2EC),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// A single banner slide: shows the banner photo if valid, otherwise
/// falls back to a decorative gradient.
///
/// TODO: banner tap-to-navigate (store / product / external link) was
/// disabled pending a redesign of the destination behaviour — re-add
/// an onTap handler here once that's finalized.
class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.gradColors});

  final BannerModel banner;
  final List<Color> gradColors;

  bool _hasValidPhoto() {
    final p = banner.bannerUrl?.toString().trim();
    if (p == null || p.isEmpty || p == 'null') return false;
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _hasValidPhoto();

    return Container(
      decoration: BoxDecoration(
        gradient: hasPhoto
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
        color: hasPhoto ? null : gradColors.first,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            NetworkImageWidget(
              imageUrl: banner.bannerUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fill,
            ),
          if (!hasPhoto) ...[
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -55,
              right: 50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 85,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x40FFFFFF),
                ),
              ),
            ),
          ],
          if (hasPhoto)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
