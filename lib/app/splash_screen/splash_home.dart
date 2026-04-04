import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jippymart_customer/app/splash_screen/video_splash_screen.dart';
import 'package:jippymart_customer/core/riverpod/global_settings_notifier.dart';

class SplashHome extends ConsumerWidget {
  const SplashHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(globalSettingsNotifierProvider);
    return const VideoSplashScreen();
  }
}
