import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _chimePlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _isSoundEnabled = true;
  String? _currentAmbientTrack;

  bool get isSoundEnabled => _isSoundEnabled;
  String? get currentAmbientTrack => _currentAmbientTrack;

  void toggleSound(bool enabled) {
    _isSoundEnabled = enabled;
    if (!enabled) {
      stopAmbient();
    }
  }

  /// Play a serene completion chime for habit completion
  Future<void> playHabitChime() async {
    if (!_isSoundEnabled) return;
    try {
      // Using low-latency audio cache or built-in asset chime
      await _chimePlayer.stop();
      await _chimePlayer.play(
        AssetSource('sounds/chime.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 0.6,
      );
    } catch (e) {
      if (kDebugMode) {
        print('playHabitChime (gracefully handled without asset): ');
      }
    }
  }

  /// Play relaxing ambient background soundscape for Focus Zone
  Future<void> playAmbient(String soundKey) async {
    if (!_isSoundEnabled) return;
    try {
      _currentAmbientTrack = soundKey;
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.5);
      await _ambientPlayer.play(AssetSource('sounds/.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('playAmbient (gracefully handled without asset): ');
      }
    }
  }

  Future<void> stopAmbient() async {
    try {
      _currentAmbientTrack = null;
      await _ambientPlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    _chimePlayer.dispose();
    _ambientPlayer.dispose();
  }
}
