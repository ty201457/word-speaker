class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.kkPhonetic,
    required this.phonemes,
    this.translation,
  });

  final String word;
  final String kkPhonetic;
  final List<PhonemeSegment> phonemes;
  final String? translation;
}

class PhonemeSegment {
  const PhonemeSegment({
    required this.symbol,
    required this.speechCue,
  });

  final String symbol;
  final String speechCue;
}
