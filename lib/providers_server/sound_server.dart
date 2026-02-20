import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class SoundServer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAndWait(
    String assetPath, {
    String fallback = 'sounds/bell-98033.mp3',
  }) async {
    await _player.stop();
    final ok = await _tryPlay(assetPath);

    if (!ok) {
      await _tryPlay(fallback);
    }
  }

  Future<bool> _tryPlay(String asset) async {
    final completer = Completer<void>();
    late StreamSubscription sub;

    try {
      sub = _player.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          sub.cancel();
        }
      });

      await _player.stop();
      await _player.play(AssetSource(asset));

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          sub.cancel();
        },
      );

      return true;
    } catch (_) {
      sub.cancel();
      return false;
    }
  }

  void dispose() {
    _player.dispose();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
