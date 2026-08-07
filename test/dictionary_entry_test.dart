import 'package:flutter_test/flutter_test.dart';
import 'package:word_speaker/models/dictionary_entry.dart';

void main() {
  test('stores an offline dictionary result', () {
    const entry = DictionaryEntry(word: 'hello', phonetic: '/həˈloʊ/');
    expect(entry.word, 'hello');
    expect(entry.phonetic, '/həˈloʊ/');
  });
}
