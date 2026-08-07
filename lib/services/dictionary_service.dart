import 'package:flutter/services.dart';
import '../models/dictionary_entry.dart';

class DictionaryException implements Exception {
  const DictionaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DictionaryService {
  Map<String, String>? _entries;

  Future<void> _load() async {
    if (_entries != null) return;
    final contents = await rootBundle.loadString('assets/cmu_ipa.tsv');
    final entries = <String, String>{};
    for (final line in contents.split('\n')) {
      final separator = line.indexOf('\t');
      if (separator <= 0) continue;
      entries[line.substring(0, separator)] = line.substring(separator + 1);
    }
    _entries = entries;
  }

  Future<DictionaryEntry> lookup(String input) async {
    final word = input.trim().toLowerCase();
    if (word.isEmpty) {
      throw const DictionaryException('請先輸入英文單字');
    }
    if (!RegExp(r"^[a-z][a-z'-]*$").hasMatch(word)) {
      throw const DictionaryException('目前只支援單一英文單字');
    }

    await _load();
    final phonetic = _entries![word];
    if (phonetic == null) {
      throw const DictionaryException('離線字庫中找不到這個單字');
    }
    return DictionaryEntry(word: word, phonetic: phonetic);
  }
}
