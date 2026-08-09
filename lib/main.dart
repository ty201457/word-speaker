import 'package:flutter/material.dart';

import 'models/dictionary_entry.dart';
import 'services/dictionary_service.dart';
import 'services/pronunciation_service.dart';
import 'widgets/accent_button.dart';

void main() => runApp(const WordSpeakerApp());

class WordSpeakerApp extends StatelessWidget {
  const WordSpeakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6255D9);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Speaker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE8E5F0)),
          ),
        ),
      ),
      home: const LookupScreen(),
    );
  }
}

class LookupScreen extends StatefulWidget {
  const LookupScreen({super.key});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  final _controller = TextEditingController();
  final _dictionary = DictionaryService();
  final _pronunciation = PronunciationService();

  DictionaryEntry? _entry;
  String? _error;
  bool _loading = false;
  EnglishAccent? _speakingAccent;
  SyllableSegment? _speakingSyllable;

  @override
  void dispose() {
    _controller.dispose();
    _pronunciation.stop();
    super.dispose();
  }

  Future<void> _lookup() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _entry = null;
    });

    try {
      final result = await _dictionary.lookup(_controller.text);
      if (!mounted) return;
      setState(() => _entry = result);
    } on DictionaryException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '離線字庫載入失敗，請重新安裝最新版本');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _speak(EnglishAccent accent) async {
    final entry = _entry;
    if (entry == null) return;
    setState(() => _speakingAccent = accent);
    try {
      await _pronunciation.speak(entry.word, accent);
    } finally {
      if (mounted) setState(() => _speakingAccent = null);
    }
  }

  Future<void> _speakSyllable(SyllableSegment syllable) async {
    setState(() => _speakingSyllable = syllable);
    try {
      await _pronunciation.speakSyllable(syllable.speechCue);
    } finally {
      if (mounted) setState(() => _speakingSyllable = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.record_voice_over_rounded,
                    size: 46,
                    color: Color(0xFF6255D9),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Word Speaker',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      '離線查音標，使用手機語音聆聽發音',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF6D6878),
                        ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _controller,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.search,
                    keyboardType: TextInputType.text,
                    onSubmitted: (_) => _lookup(),
                    decoration: InputDecoration(
                      hintText: '例如：beautiful',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清除',
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _entry = null;
                                  _error = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _lookup,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('查詢音標'),
                  ),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _resultArea(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultArea() {
    if (_error != null) {
      return Card(
        key: const ValueKey('error'),
        color: Theme.of(context).colorScheme.errorContainer,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(child: Text(_error!)),
            ],
          ),
        ),
      );
    }

    final entry = _entry;
    if (entry == null) return const SizedBox.shrink(key: ValueKey('empty'));

    return Card(
      key: ValueKey(entry.word),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: Color(0xFFE8E5F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.word,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.kkPhonetic,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF6255D9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '美式 KK 音標・離線字庫',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF777281),
                  ),
            ),
            const SizedBox(height: 18),
            Text(
              '點選音節聆聽分段發音',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6255D9),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final syllable in entry.syllables)
                  ActionChip(
                    avatar: Icon(
                      identical(_speakingSyllable, syllable)
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      size: 18,
                    ),
                    label: Text(
                      '/${syllable.phonetic}/',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: syllable.isPrimaryStress
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    onPressed: _speakingSyllable == null && _speakingAccent == null
                        ? () => _speakSyllable(syllable)
                        : null,
                  ),
              ],
            ),
            if (entry.translation != null) ...[
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '中文翻譯',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF6255D9),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.translation!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                AccentButton(
                  flag: '🇺🇸',
                  label: _speakingAccent == EnglishAccent.american
                      ? '播放中…'
                      : '美式發音',
                  onPressed: _speakingAccent == null && _speakingSyllable == null
                      ? () => _speak(EnglishAccent.american)
                      : null,
                ),
                const SizedBox(width: 12),
                AccentButton(
                  flag: '🇬🇧',
                  label: _speakingAccent == EnglishAccent.british
                      ? '播放中…'
                      : '英式發音',
                  onPressed: _speakingAccent == null && _speakingSyllable == null
                      ? () => _speak(EnglishAccent.british)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
