import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class QuranAudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentPlayingKey;

  static bool get isPlaying => _isPlaying;
  static String? get currentPlayingKey => _currentPlayingKey;

  static bool isAyahPlaying(int sura, int aya) {
    return _isPlaying && _currentPlayingKey == '$sura:$aya';
  }

  /// Check whether device has internet access to stream audio
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('everyayah.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('8.8.8.8')
            .timeout(const Duration(seconds: 2));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Get direct MP3 URL for Abdul Basit (Murattal 192kbps - high quality)
  static String getAyahAudioUrl(int sura, int aya) {
    final suraStr = sura.toString().padLeft(3, '0');
    final ayaStr = aya.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/$suraStr$ayaStr.mp3';
  }

  /// Play an ayah audio by sura and aya
  static Future<void> playAyah({
    required int sura,
    required int aya,
    required Function(bool isPlaying) onStateChanged,
  }) async {
    final key = '$sura:$aya';
    final url = getAyahAudioUrl(sura, aya);

    if (_isPlaying && _currentPlayingKey == key) {
      await stop();
      onStateChanged(false);
      return;
    }

    await _player.stop();
    _isPlaying = true;
    _currentPlayingKey = key;
    onStateChanged(true);

    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentPlayingKey = null;
      onStateChanged(false);
    });

    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      _isPlaying = false;
      _currentPlayingKey = null;
      onStateChanged(false);
    }
  }

  /// Stop current playback
  static Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentPlayingKey = null;
  }
}
