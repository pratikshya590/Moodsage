class MoodEntry {
  final String id;
  final String mood;
  final int score;
  final String trigger;
  final String note;
  final List<String> whatHelped;
  final String helpedNote;
  final DateTime createdAt;

  const MoodEntry({
    required this.id,
    required this.mood,
    required this.score,
    required this.trigger,
    required this.note,
    required this.whatHelped,
    required this.helpedNote,
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      mood: json['mood'] as String,
      score: (json['score'] as num).toInt(),
      trigger: json['trigger'] as String,
      note: (json['note'] ?? '') as String,
      whatHelped: List<String>.from(json['whatHelped'] ?? const []),
      helpedNote: (json['helpedNote'] ?? '') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
    );
  }
}