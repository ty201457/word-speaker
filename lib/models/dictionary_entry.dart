class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.phonetic,
    this.partOfSpeech,
    this.definition,
  });

  final String word;
  final String phonetic;
  final String? partOfSpeech;
  final String? definition;

  factory DictionaryEntry.fromApi(List<dynamic> json) {
    if (json.isEmpty || json.first is! Map<String, dynamic>) {
      throw const FormatException('找不到這個單字');
    }

    final first = json.first as Map<String, dynamic>;
    final phonetics = (first['phonetics'] as List<dynamic>? ?? const []);
    final topLevelPhonetic = (first['phonetic'] as String? ?? '').trim();
    final phonetic = topLevelPhonetic.isNotEmpty
        ? topLevelPhonetic
        : phonetics
            .whereType<Map<String, dynamic>>()
            .map((item) => (item['text'] as String? ?? '').trim())
            .firstWhere((text) => text.isNotEmpty, orElse: () => '暫無音標');

    String? partOfSpeech;
    String? definition;
    final meanings = first['meanings'] as List<dynamic>? ?? const [];
    if (meanings.isNotEmpty && meanings.first is Map<String, dynamic>) {
      final meaning = meanings.first as Map<String, dynamic>;
      partOfSpeech = meaning['partOfSpeech'] as String?;
      final definitions = meaning['definitions'] as List<dynamic>? ?? const [];
      if (definitions.isNotEmpty && definitions.first is Map<String, dynamic>) {
        definition =
            (definitions.first as Map<String, dynamic>)['definition'] as String?;
      }
    }

    return DictionaryEntry(
      word: first['word'] as String? ?? '',
      phonetic: phonetic,
      partOfSpeech: partOfSpeech,
      definition: definition,
    );
  }
}
