import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Built-in coin sound played when the user earns coins (e.g. daily check-in).
/// Uses [assets/sounds/coin.mp3] if present; otherwise falls back to system click.
void playCoinSound() {
  _playCoinSoundAsync();
}

Future<void> _playCoinSoundAsync() async {
  try {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/coin.mp3'));
    player.onPlayerComplete.listen((_) {
      player.dispose();
    });
    // Timeout: dispose if completion event never fires (e.g. very short clip)
    Future.delayed(const Duration(seconds: 2), () {
      try {
        player.dispose();
      } catch (_) {}
    });
  } catch (_) {
    SystemSound.play(SystemSoundType.click);
  }
}
