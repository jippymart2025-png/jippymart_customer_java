import 'package:flutter/material.dart';

import '../../../constant/constant.dart';
import '../../../core/responsive.dart';

extension ResponsiveExtension on BuildContext {
  Responsive get rs => Responsive.of(this);
}

class DealsAppBar extends StatelessWidget {
  const DealsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      color: C.surface,
      padding: EdgeInsets.fromLTRB(rs.hPad, top + 10, rs.hPad, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Text(
                      'Jippy Deals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: C.text1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text('🔥', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  Constant.selectedZone?.name?.isNotEmpty == true
                      ? '${Constant.selectedZone!.name} · Best deals, bigger savings!'
                      : 'Best deals, bigger savings!',
                  style: const TextStyle(fontSize: 11, color: C.text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
