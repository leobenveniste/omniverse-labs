import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _isSoundEnabled = true;
  String? _currentAmbientTrack;

  bool get isSoundEnabled => _isSoundEnabled;
  String? get currentAmbientTrack => _currentAmbientTrack;

  AudioService() {
    _initAudioContext();
  }

  Future<void> _initAudioContext() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('AudioContext init error: $e');
      }
    }
  }

  void toggleSound(bool enabled) {
    _isSoundEnabled = enabled;
    if (!enabled) {
      stopAmbient();
    }
  }

  /// Single habit completion chime
  Future<void> playHabitChime() async {
    if (!_isSoundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.7);
      await _sfxPlayer.play(
        AssetSource('sounds/habit_complete.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      if (kDebugMode) {
        print('playHabitChime error: $e');
      }
    }
  }

  /// Celebratory cascade chime when all habits of the day are conquered
  Future<void> playAllHabitsCompleteSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.85);
      await _sfxPlayer.play(
        AssetSource('sounds/all_habits_complete.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      if (kDebugMode) {
        print('playAllHabitsCompleteSound error: $e');
      }
    }
  }

  /// Gentle acoustic kalimba/harp pluck when a journal reflection is saved
  Future<void> playJournalSavedSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.7);
      await _sfxPlayer.play(
        AssetSource('sounds/journal_saved.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      if (kDebugMode) {
        print('playJournalSavedSound error: $e');
      }
    }
  }

  /// Calming ambient pad for the Breathing Area
  Future<void> playBreathingAmbient() async {
    if (!_isSoundEnabled) return;
    try {
      _currentAmbientTrack = 'breathing';
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.55);
      await _ambientPlayer.play(AssetSource('sounds/breathing_ambient.wav'));
    } catch (e) {
      if (kDebugMode) {
        print('playBreathingAmbient error: $e');
      }
    }
  }

  /// Gentle mindfulness pad during routine running
  Future<void> playRoutineAmbient() async {
    if (!_isSoundEnabled) return;
    try {
      _currentAmbientTrack = 'routine';
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.45);
      await _ambientPlayer.play(AssetSource('sounds/routine_ambient.wav'));
    } catch (e) {
      if (kDebugMode) {
        print('playRoutineAmbient error: $e');
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
    _sfxPlayer.dispose();
    _ambientPlayer.dispose();
  }
}
