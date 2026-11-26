import '../models/mood_entry.dart';
import 'api_service.dart';

/// One day on the mood chart
class ChartPoint {
  final DateTime date;
  final double? average; // null = no mood logged that day
  final int count;

  ChartPoint({required this.date, required this.average, required this.count});

  factory ChartPoint.fromJson(Map<String, dynamic> json) => ChartPoint(
        date: DateTime.parse(json['date'] as String),
        average: (json['average'] as num?)?.toDouble(),
        count: (json['count'] as num).toInt(),
      );
}

/// Data for the Weekly Summary screen
class WeeklySummary {
  final DateTime startDate;
  final DateTime endDate;
  final int daysLogged;
  final int totalEntries;
  final String? topMood;
  final int topMoodDays;
  final String? topTrigger;
  final int topTriggerDays;

  WeeklySummary({
    required this.startDate,
    required this.endDate,
    required this.daysLogged,
    required this.totalEntries,
    this.topMood,
    this.topMoodDays = 0,
    this.topTrigger,
    this.topTriggerDays = 0,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    final mood = json['topMood'] as Map<String, dynamic>?;
    final trigger = json['topTrigger'] as Map<String, dynamic>?;
    return WeeklySummary(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      daysLogged: (json['daysLogged'] as num).toInt(),
      totalEntries: (json['totalEntries'] as num).toInt(),
      topMood: mood?['mood'] as String?,
      topMoodDays: (mood?['days'] as num?)?.toInt() ?? 0,
      topTrigger: trigger?['trigger'] as String?,
      topTriggerDays: (trigger?['days'] as num?)?.toInt() ?? 0,
    );
  }
}

class MoodService {
  MoodService._();
  static final instance = MoodService._();

  // Sends the phone's time zone so "today" matches the user's clock
  String get _tz => 'tzOffset=${DateTime.now().timeZoneOffset.inMinutes}';

  /// Home: save a mood
  Future<MoodEntry> saveMood({
    required String mood,
    required String trigger,
    String note = '',
  }) async {
    final data = await ApiService.instance.post('/moods', {
      'mood': mood,
      'trigger': trigger,
      'note': note,
    });
    return MoodEntry.fromJson(data as Map<String, dynamic>);
  }

  /// History: all entries (newest first), optional search
  Future<List<MoodEntry>> getEntries({String search = ''}) async {
    final query = search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final data = await ApiService.instance.get('/moods$query');
    return (data as List)
        .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Entry Detail: one entry
  Future<MoodEntry> getEntry(String id) async {
    final data = await ApiService.instance.get('/moods/$id');
    return MoodEntry.fromJson(data as Map<String, dynamic>);
  }

  /// What Helped: save the ticked options + note
  Future<MoodEntry> saveWhatHelped(
    String id,
    List<String> whatHelped,
    String helpedNote,
  ) async {
    final data = await ApiService.instance.put('/moods/$id/helped', {
      'whatHelped': whatHelped,
      'helpedNote': helpedNote,
    });
    return MoodEntry.fromJson(data as Map<String, dynamic>);
  }

  /// Entry Detail: delete
  Future<void> deleteEntry(String id) async {
    await ApiService.instance.delete('/moods/$id');
  }


  /// Settings: delete ALL of the user's entries (Reset app data)
  Future<void> deleteAllEntries() async {
    await ApiService.instance.delete('/moods');
  }
  
  /// Mood Chart: 7 or 30 days
  Future<List<ChartPoint>> getChart(int days) async {
    final data = await ApiService.instance.get('/moods/chart?days=$days&$_tz');
    return ((data as Map<String, dynamic>)['points'] as List)
        .map((p) => ChartPoint.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Weekly Summary
  Future<WeeklySummary> getSummary() async {
    final data = await ApiService.instance.get('/moods/summary?$_tz');
    return WeeklySummary.fromJson(data as Map<String, dynamic>);
  }
}