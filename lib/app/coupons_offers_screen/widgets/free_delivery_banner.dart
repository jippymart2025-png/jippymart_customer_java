import 'package:flutter/material.dart';
import '../../Communityscreen/theme/app_theme.dart';

class FreeDeliveryBanner extends StatelessWidget {
  final double progress;
  final String remainingText;

  const FreeDeliveryBanner({
    super.key,
    required this.progress,
    required this.remainingText,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.bannerGradient,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE55328).withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9C9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked
                    ? Icons.local_shipping_rounded
                    : Icons.workspace_premium_outlined,
                color: const Color(0xFFE67916),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14.5, height: 1.2),
                      children: [
                        const TextSpan(
                          text: unlockedPrefix,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'FREE DELIVERY',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked
                        ? 'You\'re all set for this order.'
                        : 'Add items worth ₹149 to save more!',
                    style: const TextStyle(
                      color: Color(0xFFC86D36),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 8,
                            child: Stack(
                              children: [
                                Container(color: const Color(0xFFFFD6C8)),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: progress.clamp(0, 1),
                                  ),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) =>
                                      FractionallySizedBox(
                                        widthFactor: value,
                                        child: Container(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        remainingText,
                        style: const TextStyle(
                          color: Color(0xFFE55328),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

const String unlockedPrefix = 'Yay! You have unlocked ';
