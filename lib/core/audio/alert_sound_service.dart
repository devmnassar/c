import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays the order alert sound. Soft, modern, pleasant tone.
/// Stops any previous playback before playing. Fails silently if asset missing.
class AlertSoundService {
  static const String _assetPath = 'assets/sounds/order_alert_modern.mp3';
  static AudioPlayer? _player;
  static StreamSubscription? _completeSubscription;
  static Uint8List? _cachedBytes;

  /// Plays the order alert sound once. Stops previous sound if still playing.
  /// Volume ~0.8, ReleaseMode.stop, no looping. Optional fade-in 0.3→0.8 in 200ms.
  static Future<void> playOrderAlertSound() async {
    try {
      await _player?.stop();
      _completeSubscription?.cancel();
      _player ??= AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.stop);
      await _player!.setVolume(0.3);
      _cachedBytes ??= (await rootBundle.load(_assetPath)).buffer.asUint8List();
      await _player!.play(BytesSource(_cachedBytes!));
      _fadeInVolume();
      _completeSubscription = _player!.onPlayerComplete.listen((_) {
        _completeSubscription?.cancel();
        _completeSubscription = null;
      });
      debugPrint(
        '[ALERT SOUND] Playing asset bytes: $_assetPath (${_cachedBytes!.length} bytes)',
      );
    } catch (error, stackTrace) {
      debugPrint('[ALERT SOUND] Failed to play asset: $_assetPath');
      debugPrint('[ALERT SOUND] Error: $error');
      debugPrint('[ALERT SOUND] StackTrace: $stackTrace');
      _player?.dispose();
      _player = null;
      _completeSubscription?.cancel();
      _completeSubscription = null;
    }
  }

  /// Fade-in: 0.3 → 0.8 over 200ms (4 steps of 50ms).
  static void _fadeInVolume() {
    const steps = [0.45, 0.6, 0.75, 0.8];
    for (var i = 0; i < steps.length; i++) {
      Future.delayed(Duration(milliseconds: 50 * (i + 1)), () async {
        if (_player != null) await _player!.setVolume(steps[i]);
      });
    }
  }

  /// Stops the alert sound. Call when user leaves page or timer expires.
  static Future<void> stopOrderAlertSound() async {
    try {
      _completeSubscription?.cancel();
      _completeSubscription = null;
      await _player?.stop();
      _player?.dispose();
      _player = null;
    } catch (_) {}
  }

  /// Alias for backward compatibility.
  static Future<void> playIncomingOrderAlert() => playOrderAlertSound();
}
