import '../models/dictionary_entry.dart';
import 'dictionary_service.dart';

class DailyWordSet {
  const DailyWordSet({
    required this.oneSyllable,
    required this.twoSyllables,
    required this.multiSyllables,
  });

  final DictionaryEntry oneSyllable;
  final DictionaryEntry twoSyllables;
  final DictionaryEntry multiSyllables;

  List<DictionaryEntry> get entries =>
      [oneSyllable, twoSyllables, multiSyllables];
}

class DailyWordService {
  DailyWordService(this._dictionary);

  final DictionaryService _dictionary;

  static const _oneSyllableWords = [
    'book', 'chair', 'dream', 'friend', 'green', 'light', 'plant',
    'smile', 'sound', 'sport', 'stone', 'train', 'world', 'write',
  ];
  static const _twoSyllableWords = [
    'apple', 'happy', 'market', 'morning', 'music', 'paper', 'people',
    'picture', 'river', 'student', 'table', 'teacher', 'window', 'yellow',
  ];
  static const _multiSyllableWords = [
    'beautiful', 'computer', 'education', 'important', 'information',
    'interesting', 'opportunity', 'pronunciation', 'remember',
    'tomorrow', 'understand', 'university', 'vocabulary', 'wonderful',
  ];

  Future<DailyWordSet> wordsFor(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day)
        .difference(DateTime(2026)).inDays;
    final one = _oneSyllableWords[_positiveIndex(day, _oneSyllableWords.length)];
    final two = _twoSyllableWords[
        _positiveIndex(day * 5 + 3, _twoSyllableWords.length)];
    final multi = _multiSyllableWords[
        _positiveIndex(day * 7 + 5, _multiSyllableWords.length)];
    final results = await Future.wait([
      _dictionary.lookup(one),
      _dictionary.lookup(two),
      _dictionary.lookup(multi),
    ]);
    return DailyWordSet(
      oneSyllable: results[0],
      twoSyllables: results[1],
      multiSyllables: results[2],
    );
  }

  int _positiveIndex(int value, int length) => (value % length + length) % length;
}
