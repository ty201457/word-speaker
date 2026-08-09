import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    final parts = await Future.wait([
      for (var index = 0; index < 7; index++)
        rootBundle.load('assets/offline_dictionary.tsv.gz.part$index'),
    ]);
    final bytes = Uint8List(parts.fold<int>(0, (sum, part) => sum + part.lengthInBytes));
    var offset = 0;
    for (final part in parts) {
      final chunk = part.buffer.asUint8List(part.offsetInBytes, part.lengthInBytes);
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _dictionaryText = utf8.decode(gzip.decode(bytes));
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
      '^${RegExp.escape(word)}\\t([^\\t\\n]+)\\t([^\\n]*)',
      multiLine: true,
    ).firstMatch(_dictionaryText!);
    if (match == null) {
      throw const DictionaryException('離線字庫中找不到這個單字');
    }
    final phonetic = _decodeUnicodeEscapes(match.group(1)!);
    final translation = _decodeUnicodeEscapes(match.group(2)!);
    final kkPhonetic = _toKk(phonetic);
    return DictionaryEntry(
      word: word,
      kkPhonetic: kkPhonetic,
      phonemes: _segmentKk(kkPhonetic),
      translation: translation.isEmpty ? null : translation,
    );
  }

  String _decodeUnicodeEscapes(String value) {
    return value.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
  }

  String _toKk(String ipa) {
    const replacements = <String, String>{
      'eɪ': 'e',
      'oʊ': 'o',
      'ɡ': 'g',
      'ɹ': 'r',
    };
    var result = ipa.replaceAll('/', '').split('#').first;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return '/$result/';
  }

  List<PhonemeSegment> _segmentKk(String phonetic) {
    const cues = <String, String>{
      'aɪ': 'eye', 'aʊ': 'ow', 'ɔɪ': 'oy', 'tʃ': 'ch', 'dʒ': 'juh',
      'i': 'ee', 'ɪ': 'ih', 'e': 'ay', 'ɛ': 'eh', 'æ': 'aa',
      'ɑ': 'ah', 'ɔ': 'aw', 'o': 'oh', 'ʊ': 'book', 'u': 'oo',
      'ʌ': 'uh', 'ə': 'uh', 'ɝ': 'er', 'ɚ': 'er', 'p': 'puh',
      'b': 'buh', 't': 'tuh', 'd': 'duh', 'k': 'kuh', 'g': 'guh',
      'f': 'fff', 'v': 'vvv', 'θ': 'th', 'ð': 'the', 's': 'sss',
      'z': 'zzz', 'ʃ': 'sh', 'ʒ': 'zh', 'h': 'huh', 'm': 'mmm',
      'n': 'nnn', 'ŋ': 'ng', 'l': 'lll', 'r': 'rrr', 'j': 'yee',
      'w': 'woo',
    };
    final source = phonetic.replaceAll(RegExp(r'[/ˈˌ.]'), '');
    final symbols = cues.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final result = <PhonemeSegment>[];
    var index = 0;
    while (index < source.length) {
      String? symbol;
      for (final candidate in symbols) {
        if (source.startsWith(candidate, index)) {
          symbol = candidate;
          break;
        }
      }
      if (symbol == null) {
        index++;
        continue;
      }
      result.add(PhonemeSegment(symbol: symbol, speechCue: cues[symbol]!));
      index += symbol.length;
    }
    return result;
  }
}
