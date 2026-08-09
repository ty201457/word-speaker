import 'package:flutter_test/flutter_test.dart';
import 'package:word_speaker/models/dictionary_entry.dart';

void main() {
  test('stores an offline dictionary result', () {
    const entry = DictionaryEntry(
      word: 'hello',
      kkPhonetic: '/həˈlo/',
      phonemes: [
        PhonemeSegment(symbol: 'h', speechCue: 'huh'),
        PhonemeSegment(symbol: 'ə', speechCue: 'uh'),
        PhonemeSegment(symbol: 'l', speechCue: 'lll'),
        PhonemeSegment(symbol: 'o', speechCue: 'oh'),
      ],
      translation: '喂、嘿',
    );
    expect(entry.word, 'hello');
    expect(entry.kkPhonetic, '/həˈlo/');
    expect(entry.phonemes.map((item) => item.symbol), ['h', 'ə', 'l', 'o']);
    expect(entry.translation, '喂、嘿');
  });
}
