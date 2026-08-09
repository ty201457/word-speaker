import 'package:flutter_tts/flutter_tts.dart';

enum EnglishAccent {
  american('美式', 'en-US'),
  british('英式', 'en-GB');

  const EnglishAccent(this.label, this.locale);
  final String label;
  final String locale;
}

class PronunciationService {
  PronunciationService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  Future<void> speak(String word, EnglishAccent accent) async {
    await _tts.stop();
    await _tts.setLanguage(accent.locale);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(word);
  }

  Future<void> speakSyllable(String speechCue) async {
    await _tts.stop();
    await _tts.setLanguage(EnglishAccent.american.locale);
    await _tts.setSpeechRate(0.32);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(speechCue);
  }

  Future<void> stop() => _tts.stop();
}
