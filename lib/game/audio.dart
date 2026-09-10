import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Asset-backed SFX and looping background music for the game.
class GameAudio {
  GameAudio() {
    final context = _audioContext();
    unawaited(AudioPlayer.global.setAudioContext(context));
    unawaited(_bgm.setAudioContext(context));
    for (var i = 0; i < _poolSize; i++) {
      final player = AudioPlayer(playerId: 'sfx_$i');
      unawaited(player.setAudioContext(_audioContext()));
      _players.add(player);
    }
  }

  static const int _poolSize = 6;
  final List<AudioPlayer> _players = [];
  final AudioPlayer _bgm = AudioPlayer(playerId: 'rolling_jungle_bgm');
  int _poolIndex = 0;
  int? _bgmTrack;
  bool _bgmPlaying = false;
  bool _unlocked = false;
  bool _disposed = false;

  AudioContext _audioContext() => AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  void _play(String name, {double volume = 0.75, double pitch = 1}) {
    if (_disposed || !_unlocked || _players.isEmpty) return;
    final player = _players[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _poolSize;
    unawaited(_playSafely(player, name, volume, pitch));
  }

  Future<void> _playSafely(
    AudioPlayer player,
    String name,
    double volume,
    double pitch,
  ) async {
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource('audio/$name.mp3'));
      if (pitch != 1) {
        try {
          await player.setPlaybackRate(pitch.clamp(0.7, 1.35));
        } catch (_) {
          // Playback rate is optional and unsupported on some platforms.
        }
      }
    } catch (_) {
      // Audio is non-critical; never break gameplay.
    }
  }

  int _trackForLevel(int level) => ((level.clamp(1, 10) - 1) ~/ 2) + 1;

  Future<void> _startBgm(int level) async {
    if (_disposed || !_unlocked) return;
    final track = _trackForLevel(level);
    if (_bgmPlaying && _bgmTrack == track) {
      await _bgm.resume();
      return;
    }
    try {
      await _bgm.stop();
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.22);
      await _bgm.play(AssetSource('audio/bgm$track.mp3'));
      _bgmTrack = track;
      _bgmPlaying = true;
    } catch (_) {
      _bgmTrack = null;
      _bgmPlaying = false;
    }
  }

  void unlock() {
    if (_disposed) return;
    _unlocked = true;
  }

  void setLevelBgm(int level) {
    if (_disposed || !_unlocked) return;
    unawaited(_startBgm(level));
  }

  Future<void> pauseBgm() => _bgm.pause();

  Future<void> resumeBgm() => _bgm.resume();

  void play(String name, [double pitch = 1]) {
    _play(name, pitch: pitch);
  }

  Future<void> destroy() async {
    _disposed = true;
    await _bgm.stop();
    await _bgm.dispose();
    for (final player in _players) {
      await player.dispose();
    }
    _players.clear();
  }
}
