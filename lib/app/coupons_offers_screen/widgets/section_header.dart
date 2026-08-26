import 'package:flutter/material.dart';

import '../../Communityscreen/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.onTrailingTap,
  });

  static const _titleStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const _subtitleStyle = TextStyle(
    fontSize: 13.5,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  static const _trailingStyle = TextStyle(
    fontSize: 14,
    color: AppColors.primaryDark,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: trailingLabel == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: _subtitleStyle),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(title, style: _titleStyle.copyWith(fontSize: 18)),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onTrailingTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(trailingLabel!, style: _trailingStyle),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
