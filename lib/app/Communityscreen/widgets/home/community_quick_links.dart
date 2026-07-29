import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../screens/community_deals_screen.dart';
import '../../screens/events_screen.dart';
import '../../theme/app_theme.dart';

/// The four-icon quick-link row directly under the community card —
/// mirrors the reference design's "Group Orders / Community Deals /
/// Events / Community Chat" shortcuts on the Community Home screen.
class CommunityQuickLinks extends ConsumerWidget {
  const CommunityQuickLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = [
      _QuickLink(
        icon: Icons.groups_rounded,
        label: 'Group Orders',
        subtitle: 'Save together',
        color: AppColors.primary,
        // Wired to the real Create/Group Order tab we already have.
        onTap: () => ref.read(selectedIndexProvider.notifier).state = 1,
      ),
      _QuickLink(
        icon: Icons.local_offer_rounded,
        label: 'Community Deals',
        subtitle: 'Exclusive offers',
        color: AppColors.success,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CommunityDealsScreen())),
      ),
      _QuickLink(
        icon: Icons.event_rounded,
        label: 'Events',
        subtitle: "What's happening",
        color: AppColors.warning,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const EventsScreen())),
      ),
      // _QuickLink(
      //   icon: Icons.forum_rounded,
      //   label: 'Community Chat',
      //   subtitle: 'Connect with all',
      //   color: AppColors.accentPurple,
      //   onTap: () => _comingSoon(context, 'Community Chat'),
      // ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(links.length * 2 - 1, (i) {
          // Interleave tiles with hairline dividers instead of relying
          // on whitespace alone — makes four equal-width columns read
          // as distinct actions rather than one ambiguous row.
          if (i.isOdd) return _Separator();
          final link = links[i ~/ 2];
          return Expanded(child: _QuickLinkTile(link: link));
        }),
      ),
    );
  }

  // These sections aren't built yet — a snackbar beats a dead button
  // that silently does nothing when tapped.
  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}

class _QuickLink {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 0.75,
        height: 32,
        color: AppColors.textPrimary.withOpacity(0.06),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final _QuickLink link;

  const _QuickLinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${link.label}, ${link.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: link.onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          // Minimum ~48dp touch target even though the visible icon
          // badge is smaller — avoids a cramped, hard-to-tap row.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: link.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(link.icon, color: link.color, size: 21),
                ),
                const SizedBox(height: 8),
                Text(
                  link.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  link.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 9.5, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
