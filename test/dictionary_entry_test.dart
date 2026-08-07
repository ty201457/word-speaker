import 'package:flutter_test/flutter_test.dart';
import 'package:word_speaker/models/dictionary_entry.dart';

void main() {
  test('parses a dictionary response', () {
    final entry = DictionaryEntry.fromApi([
      {
        'word': 'hello',
        'phonetic': '/həˈləʊ/',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {'definition': 'A greeting.'},
            ],
          },
        ],
      },
    ]);

    expect(entry.word, 'hello');
    expect(entry.phonetic, '/həˈləʊ/');
    expect(entry.partOfSpeech, 'noun');
    expect(entry.definition, 'A greeting.');
  });

  test('falls back to phonetics list', () {
    final entry = DictionaryEntry.fromApi([
      {
        'word': 'test',
        'phonetics': [
          {'text': ''},
          {'text': '/test/'},
        ],
      },
    ]);

    expect(entry.phonetic, '/test/');
  });
}
