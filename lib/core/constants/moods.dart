import 'package:flutter/material.dart';

// ---------- Moods (Home screen emojis) ----------
class MoodOption {
  final String key;       // saved in the database, e.g. 'happy'
  final String label;     // shown to the user, e.g. 'Happy'
  final IconData icon;
  final Color color;      // circle colour
  final Color iconColor;  // face colour
  final int score;        // chart height: 5 = top, 1 = bottom

  const MoodOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.score,
  });
}

class AppMoods {
  static const all = [
    MoodOption(
      key: 'sad',
      label: 'Sad',
      icon: Icons.sentiment_dissatisfied,
      color: Color(0xFFF26B6B),
      iconColor: Colors.white,
      score: 2,
    ),
    MoodOption(
      key: 'happy',
      label: 'Happy',
      icon: Icons.sentiment_satisfied_alt,
      color: Color(0xFFFFD43B),
      iconColor: Colors.black,
      score: 5,
    ),
    MoodOption(
      key: 'angry',
      label: 'Angry',
      icon: Icons.mood_bad,
      color: Color(0xFFF08A3C),
      iconColor: Color(0xFF7A2E0E),
      score: 3,
    ),
    MoodOption(
      key: 'neutral',
      label: 'Neutral',
      icon: Icons.sentiment_neutral,
      color: Color(0xFF7ED69B),
      iconColor: Color(0xFF1B6B3A),
      score: 4,
    ),
    MoodOption(
      key: 'cry',
      label: 'Cry',
      icon: Icons.sentiment_very_dissatisfied,
      color: Color(0xFFF8C9A0),
      iconColor: Color(0xFF3A7BD5),
      score: 1,
    ),
  ];

  static MoodOption byKey(String key) =>
      all.firstWhere((m) => m.key == key, orElse: () => all[3]);

  /// For the chart: top (score 5) to bottom (score 1)
  static List<MoodOption> get byScoreDesc =>
      [...all]..sort((a, b) => b.score.compareTo(a.score));
}

// ---------- Triggers ("What's behind it?") ----------
class TriggerOption {
  final String key;
  final String label;
  final IconData icon;

  const TriggerOption({required this.key, required this.label, required this.icon});
}

class AppTriggers {
  static const all = [
    TriggerOption(key: 'sleep', label: 'Sleep', icon: Icons.bedtime_outlined),
    TriggerOption(key: 'work', label: 'Work', icon: Icons.work_outline),
    TriggerOption(key: 'relationship', label: 'Relationship', icon: Icons.favorite_border),
    TriggerOption(key: 'money', label: 'Money', icon: Icons.payments_outlined),
    TriggerOption(key: 'health', label: 'Health', icon: Icons.medical_services_outlined),
    TriggerOption(key: 'other', label: 'Other', icon: Icons.more_horiz),
  ];

  static TriggerOption byKey(String key) =>
      all.firstWhere((t) => t.key == key, orElse: () => all.last);
}

// ---------- "What helped?" options ----------
class HelpedOption {
  final String key;
  final String label;
  final IconData icon;

  const HelpedOption({required this.key, required this.label, required this.icon});
}

class AppHelped {
  static const all = [
    HelpedOption(key: 'breathing', label: 'Breathing', icon: Icons.air),
    HelpedOption(key: 'music', label: 'Music', icon: Icons.music_note),
    HelpedOption(key: 'movement', label: 'Movement', icon: Icons.self_improvement),
    HelpedOption(key: 'break', label: 'Took a break', icon: Icons.local_cafe_outlined),
    HelpedOption(key: 'talked', label: 'Talked to someone', icon: Icons.chat_bubble_outline),
    HelpedOption(key: 'other', label: 'Something else', icon: Icons.edit_outlined),
  ];

  static HelpedOption byKey(String key) =>
      all.firstWhere((h) => h.key == key, orElse: () => all.last);
}