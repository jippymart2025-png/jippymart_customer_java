import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import 'appbar.dart';

/// Shown when there are no deals or banners for the current zone.
class DealsEmptyState extends StatelessWidget {
  const DealsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: C.brandLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('🎁', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No deals right now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: C.text1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pull down to refresh',
                  style: TextStyle(fontSize: 13, color: C.text3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
