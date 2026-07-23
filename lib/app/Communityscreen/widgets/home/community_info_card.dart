import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Matches the "Community Home" reference design:
/// photo thumbnail + name/info-pill + location, with a stat row
/// (Families · Active Orders · Rating) underneath, divided by hairlines.
class CommunityInfoCard extends StatelessWidget {
  final CommunityData community;
  final VoidCallback? onInfoTap;

  /// Optional thumbnail. Pass this in from wherever the community photo
  /// actually lives (e.g. `community.someExistingImageField`) until/unless
  /// you add a dedicated `imageUrl` field to CommunityData. Falls back to
  /// an icon placeholder when null.
  final String? imageUrl;

  const CommunityInfoCard({
    super.key,
    required this.community,
    this.onInfoTap,
    this.imageUrl =
        "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 84,
                    height: 84,
                    color: Colors.white.withOpacity(0.16),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name / info pill / location / stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        community.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _InfoPill(onTap: onInfoTap),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        community.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.groups_rounded,
                      value: community.families,
                      label: 'Families',
                    ),
                    _StatDivider(),
                    _Stat(
                      icon: Icons.receipt_long_rounded,
                      value: community.activeOrders,
                      label: 'Active Orders',
                    ),
                    _StatDivider(),
                    _Stat(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFC94A),
                      value: community.rating,
                      label: 'Rating',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final VoidCallback? onTap;

  const _InfoPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Community Info',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 13,
                color: Colors.white.withOpacity(0.95),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.75,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withOpacity(0.25),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: iconColor ?? Colors.white.withOpacity(0.85),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
