import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dictionary_entry.dart';
import '../services/daily_word_service.dart';
import '../services/dictionary_service.dart';
import '../services/notification_service.dart';
import '../services/pronunciation_service.dart';

class DailyTrainingScreen extends StatefulWidget {
  const DailyTrainingScreen({super.key});

  @override
  State<DailyTrainingScreen> createState() => _DailyTrainingScreenState();
}

class _DailyTrainingScreenState extends State<DailyTrainingScreen> {
  final _dictionary = DictionaryService();
  final _pronunciation = PronunciationService();
  late final DailyWordService _dailyWords = DailyWordService(_dictionary);
  late final Future<DailyWordSet> _words = _dailyWords.wordsFor(DateTime.now());

  final _revealed = <String>{};
  final _remembered = <String>{};
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  String get _dateKey {
    final now = DateTime.now();
    return 'daily_progress_${now.year}_${now.month}_${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final time = await NotificationService.instance.reminderTime();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled =
          preferences.getBool('daily_notification_enabled') ?? false;
      _reminderTime = TimeOfDay(hour: time.hour, minute: time.minute);
      _remembered.addAll(preferences.getStringList(_dateKey) ?? const []);
    });
  }

  Future<void> _toggleRemembered(String word) async {
    setState(() {
      if (!_remembered.add(word)) _remembered.remove(word);
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_dateKey, _remembered.toList());
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      if (enabled) {
        await NotificationService.instance.scheduleDaily(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
      } else {
        await NotificationService.instance.disable();
      }
      if (mounted) setState(() => _notificationsEnabled = enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請在系統設定中允許通知')),
      );
    }
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (selected == null) return;
    setState(() => _reminderTime = selected);
    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleDaily(
        hour: selected.hour,
        minute: selected.minute,
      );
    }
  }

  Future<void> _speakWord(String word) =>
      _pronunciation.speak(word, EnglishAccent.american);

  Future<void> _speakSyllable(SyllableSegment syllable) =>
      _pronunciation.speakSyllable(syllable.speechCue);

  String _labelFor(int index) => switch (index) {
        0 => '單音節',
        1 => '雙音節',
        _ => '多音節',
      };

  @override
  void dispose() {
    _pronunciation.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('每日單字訓練')),
      body: FutureBuilder<DailyWordSet>(
        future: _words,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('今日單字載入失敗'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!.entries;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '今日進度 ${_remembered.length} / 3',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _remembered.length / 3),
              const SizedBox(height: 20),
              for (var index = 0; index < entries.length; index++)
                _wordCard(entries[index], _labelFor(index)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('每天提醒'),
                      subtitle: Text(
                        '提醒時間：${_reminderTime.format(context)}',
                      ),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('修改提醒時間'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _chooseTime,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _wordCard(DictionaryEntry entry, String level) {
    final revealed = _revealed.contains(entry.word);
    final remembered = _remembered.contains(entry.word);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Chip(label: Text(level)),
                const Spacer(),
                IconButton(
                  tooltip: '播放整字',
                  onPressed: () => _speakWord(entry.word),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
            Text(
              entry.word,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (!revealed) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() => _revealed.add(entry.word)),
                child: const Text('揭曉音標與意思'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                entry.kkPhonetic,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF6255D9),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final syllable in entry.syllables)
                    ActionChip(
                      label: Text('/${syllable.phonetic}/'),
                      avatar: const Icon(Icons.volume_down_rounded, size: 18),
                      onPressed: () => _speakSyllable(syllable),
                    ),
                ],
              ),
              if (entry.translation != null) ...[
                const SizedBox(height: 12),
                Text(entry.translation!),
              ],
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _toggleRemembered(entry.word),
                icon: Icon(
                  remembered
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(remembered ? '已記住' : '標記為已記住'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
