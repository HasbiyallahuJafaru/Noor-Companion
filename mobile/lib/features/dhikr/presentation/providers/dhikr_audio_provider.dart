/// Audio controller for a single dhikr item.
/// Uses ChangeNotifier so it can be wrapped in ListenableBuilder for reactive UI.
/// Create in State.initState with the item's audioUrl, dispose in State.dispose.
library;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class DhikrAudioState {
  const DhikrAudioState({
    this.isLoading = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  /// Non-null when playback initialisation failed.
  final String? error;

  bool get hasError => error != null;

  DhikrAudioState copyWith({
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? error,
  }) =>
      DhikrAudioState(
        isLoading: isLoading ?? this.isLoading,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        error: error,
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

/// Wraps [AudioPlayer] for a single dhikr audio URL.
/// Notify is called on every state change so [ListenableBuilder] rebuilds.
class DhikrAudioController extends ChangeNotifier {
  DhikrAudioController(this.audioUrl);

  final String audioUrl;
  AudioPlayer? _player;
  DhikrAudioState _state = const DhikrAudioState();

  DhikrAudioState get state => _state;

  /// Toggles play/pause. Loads and initialises the player on the first call.
  Future<void> togglePlayback() async {
    if (_player == null) {
      await _load();
      return;
    }

    if (_state.isPlaying) {
      await _player!.pause();
      _emit(_state.copyWith(isPlaying: false));
    } else {
      await _player!.play();
      _emit(_state.copyWith(isPlaying: true));
    }
  }

  /// Seeks to [position] within the loaded audio.
  Future<void> seekTo(Duration position) async {
    await _player?.seek(position);
    _emit(_state.copyWith(position: position));
  }

  Future<void> _load() async {
    _emit(_state.copyWith(isLoading: true, error: null));
    try {
      _player = AudioPlayer();

      _player!.positionStream.listen((pos) {
        _emit(_state.copyWith(position: pos));
      });
      _player!.playerStateStream.listen((ps) {
        _emit(_state.copyWith(isPlaying: ps.playing));
      });

      final duration = await _player!.setUrl(audioUrl);
      _emit(_state.copyWith(
        isLoading: false,
        duration: duration ?? Duration.zero,
      ));
      await _player!.play();
      _emit(_state.copyWith(isPlaying: true));
    } catch (_) {
      _emit(_state.copyWith(isLoading: false, error: 'Playback failed.'));
    }
  }

  void _emit(DhikrAudioState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
