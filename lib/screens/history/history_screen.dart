import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/moods.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/mood_entry.dart';
import '../../services/api_service.dart';
import '../../services/mood_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/mood_emoji.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce; // waits until the user stops typing

  List<MoodEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Get entries from the backend (with the current search text)
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries =
          await MoodService.instance.getEntries(search: _searchCtrl.text);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  // Search 400ms after the user stops typing (not on every letter)
  void _onSearchChanged(String _) {
    setState(() {}); // show/hide the clear (x) button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openEntry(MoodEntry entry) async {
    await Navigator.pushNamed(context, AppRoutes.entryDetail, arguments: entry.id);
    // Reload when coming back (the entry may have been deleted)
    if (mounted) _load();
  }

  // "Today  10:30 AM", "Yesterday  9:00 AM", "Sep 27  7:02 PM"
  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final daysAgo = today.difference(day).inDays;
    final time = DateFormat('h:mm a').format(date);

    if (daysAgo == 0) return 'Today  $time';
    if (daysAgo == 1) return 'Yesterday  $time';
    if (date.year == now.year) return '${DateFormat('MMM d').format(date)}  $time';
    return '${DateFormat('MMM d, y').format(date)}  $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: LeafBackground(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _header(),
              const SizedBox(height: 20),
              _searchBox(),
              const SizedBox(height: 20),
              ..._body(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Logo + "Your History" + Mood chart button ----------
  Widget _header() {
    return Stack(
      children: [
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 100),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 110),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Your History',
                  style: AppTextStyles.heading.copyWith(fontSize: 38),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Look back on your moods and reflections.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: AppColors.mediumGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Clear button to open the mood chart
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.moodChart),
                icon: const Icon(Icons.show_chart, size: 22),
                label: const Text('View your mood chart'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkGreen,
                  backgroundColor: const Color(0xFFEAF3DC),
                  side: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ),

                            const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.weeklySummary),
                icon: const Icon(Icons.insights, size: 20),
                label: const Text("See this week's summary"),
                style: TextButton.styleFrom(foregroundColor: AppColors.linkGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Search box ----------
  Widget _searchBox() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search notes or triggers',
        prefixIcon: const Icon(Icons.search, size: 28, color: Colors.black87),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                  _load();
                },
              ),
        fillColor: const Color(0xFFF7F7F2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF4E6B2E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  // ---------- List / loading / empty / error ----------
  List<Widget> _body() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [
        const SizedBox(height: 40),
        Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body),
        const SizedBox(height: 12),
        Center(
          child: TextButton(onPressed: _load, child: const Text('Try again')),
        ),
      ];
    }

    if (_entries.isEmpty) {
      final searching = _searchCtrl.text.trim().isNotEmpty;
      return [
        const SizedBox(height: 50),
        Icon(
          searching ? Icons.search_off : Icons.eco_outlined,
          size: 48,
          color: AppColors.mediumGreen,
        ),
        const SizedBox(height: 12),
        Text(
          searching
              ? 'No entries match "${_searchCtrl.text.trim()}".'
              : 'No moods yet.\nLog your first mood on Home 🌿',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            color: const Color(0xFF4A4A4A),
          ),
        ),
      ];
    }

    return _entries
        .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _entryCard(e),
            ))
        .toList();
  }

  // ---------- One history card ----------
  Widget _entryCard(MoodEntry entry) {
    final mood = AppMoods.byKey(entry.mood);
    final trigger = AppTriggers.byKey(entry.trigger);

    return Material(
      color: const Color(0xFFF9F9F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openEntry(entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              MoodEmoji(mood: mood, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel(entry.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _triggerChip(trigger),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 15,
                          color: AppColors.mediumGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _triggerChip(TriggerOption trigger) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6DD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreenBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trigger.icon, size: 16, color: const Color(0xFF2B2B2B)),
          const SizedBox(width: 5),
          Text(
            trigger.label,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2B2B2B)),
          ),
        ],
      ),
    );
  }
}