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
      syllables: _segmentSyllables(kkPhonetic),
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

  List<SyllableSegment> _segmentSyllables(String phonetic) {
    const vowels = {'aɪ', 'aʊ', 'ɔɪ', 'i', 'ɪ', 'e', 'ɛ', 'æ', 'ɑ', 'ɔ',
      'o', 'ʊ', 'u', 'ʌ', 'ə', 'ɝ', 'ɚ'};
    const symbols = ['aɪ', 'aʊ', 'ɔɪ', 'tʃ', 'dʒ', 'i', 'ɪ', 'e', 'ɛ', 'æ',
      'ɑ', 'ɔ', 'o', 'ʊ', 'u', 'ʌ', 'ə', 'ɝ', 'ɚ', 'p', 'b', 't', 'd',
      'k', 'g', 'f', 'v', 'θ', 'ð', 's', 'z', 'ʃ', 'ʒ', 'h', 'm', 'n',
      'ŋ', 'l', 'r', 'j', 'w'];
    const legalOnsets = {'p', 'b', 't', 'd', 'k', 'g', 'f', 'v', 'θ', 'ð',
      's', 'z', 'ʃ', 'ʒ', 'h', 'm', 'n', 'l', 'r', 'j', 'w', 'tʃ', 'dʒ',
      'pr', 'tr', 'kr', 'br', 'dr', 'gr', 'fr', 'θr', 'ʃr', 'sp', 'st',
      'sk', 'sm', 'sn', 'sl', 'sw', 'pl', 'kl', 'bl', 'gl', 'fl', 'kw',
      'gw', 'tw', 'dw', 'pj', 'bj', 'tj', 'dj', 'kj', 'gj', 'fj', 'vj',
      'θj', 'sj', 'zj', 'hj', 'mj', 'nj', 'lj', 'rj', 'spr', 'str', 'skr',
      'spl', 'skw'};

    final source = phonetic.replaceAll('/', '');
    final tokens = <String>[];
    final primaryStressAt = <int>{};
    final secondaryStressAt = <int>{};
    var index = 0;
    String? pendingStress;
    while (index < source.length) {
      final character = source[index];
      if (character == 'ˈ' || character == 'ˌ') {
        pendingStress = character;
        index++;
        continue;
      }
      String? matched;
      for (final candidate in symbols) {
        if (source.startsWith(candidate, index)) {
          matched = candidate;
          break;
        }
      }
      if (matched == null) {
        index++;
        continue;
      }
      if (pendingStress == 'ˈ') primaryStressAt.add(tokens.length);
      if (pendingStress == 'ˌ') secondaryStressAt.add(tokens.length);
      pendingStress = null;
      tokens.add(matched);
      index += matched.length;
    }

    final nuclei = <int>[
      for (var i = 0; i < tokens.length; i++) if (vowels.contains(tokens[i])) i,
    ];
    if (nuclei.isEmpty) return const [];

    final boundaries = <int>[0];
    for (var i = 0; i < nuclei.length - 1; i++) {
      final nextNucleus = nuclei[i + 1];
      final consonantStart = nuclei[i] + 1;
      var onsetLength = 0;
      for (var length = nextNucleus - consonantStart; length >= 1; length--) {
        final onset = tokens.sublist(nextNucleus - length, nextNucleus).join();
        if (legalOnsets.contains(onset)) {
          onsetLength = length;
          break;
        }
      }
      boundaries.add(nextNucleus - onsetLength);
    }
    boundaries.add(tokens.length);

    final result = <SyllableSegment>[];
    for (var i = 0; i < boundaries.length - 1; i++) {
      final start = boundaries[i];
      final end = boundaries[i + 1];
      final syllableTokens = tokens.sublist(start, end);
      final primary = primaryStressAt.any((position) => position >= start && position < end);
      final secondary = secondaryStressAt.any((position) => position >= start && position < end);
      result.add(SyllableSegment(
        phonetic: '${primary ? 'ˈ' : secondary ? 'ˌ' : ''}${syllableTokens.join()}',
        speechCue: _syllableCue(syllableTokens),
        isPrimaryStress: primary,
        isSecondaryStress: secondary,
      ));
    }
    return result;
  }

  String _syllableCue(List<String> tokens) {
    const spelling = <String, String>{
      'aɪ': 'eye', 'aʊ': 'ow', 'ɔɪ': 'oy', 'tʃ': 'ch', 'dʒ': 'j',
      'i': 'ee', 'ɪ': 'ih', 'e': 'ay', 'ɛ': 'eh', 'æ': 'a',
      'ɑ': 'ah', 'ɔ': 'aw', 'o': 'oh', 'ʊ': 'oo', 'u': 'oo',
      'ʌ': 'uh', 'ə': 'uh', 'ɝ': 'er', 'ɚ': 'er', 'θ': 'th',
      'ð': 'th', 'ʃ': 'sh', 'ʒ': 'zh', 'ŋ': 'ng', 'j': 'y',
    };
    return tokens.map((token) => spelling[token] ?? token).join();
  }
}
