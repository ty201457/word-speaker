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
      rootBundle.load('assets/cmu_ipa.tsv.gz.part0'),
      rootBundle.load('assets/cmu_ipa.tsv.gz.part1'),
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
      '^${RegExp.escape(word)}\\t([^\\n]+)',
      multiLine: true,
    ).firstMatch(_dictionaryText!);
    if (match == null) {
      throw const DictionaryException('離線字庫中找不到這個單字');
    }
    return DictionaryEntry(
      word: word,
      phonetic: _decodeUnicodeEscapes(match.group(1)!),
    );
  }

  String _decodeUnicodeEscapes(String value) {
    return value.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
  }
}
