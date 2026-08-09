class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.kkPhonetic,
    required this.syllables,
    this.translation,
  });

  final String word;
  final String kkPhonetic;
  final List<SyllableSegment> syllables;
  final String? translation;
}

class SyllableSegment {
  const SyllableSegment({
    required this.phonetic,
    required this.speechCue,
    this.isPrimaryStress = false,
    this.isSecondaryStress = false,
  });

  final String phonetic;
  final String speechCue;
  final bool isPrimaryStress;
  final bool isSecondaryStress;
}
