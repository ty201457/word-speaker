import 'package:flutter_test/flutter_test.dart';
import 'package:word_speaker/models/dictionary_entry.dart';

void main() {
  test('stores an offline dictionary result', () {
    const entry = DictionaryEntry(
      word: 'hello',
      kkPhonetic: '/həˈlo/',
      syllables: [
        SyllableSegment(phonetic: 'hə', speechCue: 'huh'),
        SyllableSegment(phonetic: 'ˈlo', speechCue: 'loh', isPrimaryStress: true),
      ],
      translation: '喂、嘿',
    );
    expect(entry.word, 'hello');
    expect(entry.kkPhonetic, '/həˈlo/');
    expect(entry.syllables.map((item) => item.phonetic), ['hə', 'ˈlo']);
    expect(entry.translation, '喂、嘿');
  });
}
