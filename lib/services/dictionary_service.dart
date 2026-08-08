import 'package:flutter/services.dart';
import '../models/dictionary_entry.dart';

class DictionaryException implements Exception {
  const DictionaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DictionaryService {
  String? _dictionaryText;

  Future<void> _load() async {
    if (_dictionaryText != null) return;
    _dictionaryText = await rootBundle.loadString('assets/cmu_ipa.tsv');
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
    final match = RegExp(
      '^${RegExp.escape(word)}\\t([^\\n]+)',
      multiLine: true,
    ).firstMatch(_dictionaryText!);
    if (match == null) {
      throw const DictionaryException('離線字庫中找不到這個單字');
    }
    return DictionaryEntry(word: word, phonetic: match.group(1)!);
  }
}
