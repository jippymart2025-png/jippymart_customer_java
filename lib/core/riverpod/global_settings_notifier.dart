import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jippymart_customer/app/home_screen/provider/global_settings_provider.dart';

/// One app-wide [GlobalSettingsProvider]; [notifyListeners] behavior unchanged.
final globalSettingsNotifierProvider =
    ChangeNotifierProvider<GlobalSettingsProvider>((ref) {
  final notifier = GlobalSettingsProvider();
  ref.onDispose(notifier.dispose);
  return notifier;
});
