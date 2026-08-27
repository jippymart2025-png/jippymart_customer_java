import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/responsive.dart';

/// Alternates between the estimated delivery time and a "Fast
/// delivery" badge every few seconds.
class DeliveryTicker extends StatefulWidget {
  const DeliveryTicker({super.key, required this.deliveryTime});

  final String deliveryTime;

  @override
  State<DeliveryTicker> createState() => _DeliveryTickerState();
}

class _DeliveryTickerState extends State<DeliveryTicker> {
  bool _showFast = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _showFast = !_showFast);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _showFast ? _fastRow() : _timeRow(),
    );
  }

  Widget _fastRow() => Row(
    key: const ValueKey('fast'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.delivery_dining_rounded, size: 11, color: C.brand),
      const SizedBox(width: 3),
      const Text(
        'Fast delivery',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: C.brand,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  Widget _timeRow() => Row(
    key: const ValueKey('time'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.access_time_rounded, size: 10, color: C.text3),
      const SizedBox(width: 3),
      Text(
        widget.deliveryTime,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: C.text3,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
