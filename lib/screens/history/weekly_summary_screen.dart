import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/moods.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/mood_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/mood_emoji.dart';

// Weekly Summary screen. Owner: Kripa K.C (Person B)
// Shows the last 7 days: check-ins, most common mood and trigger, and a tip.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  WeeklySummary? _summary;
  List<ChartPoint> _days = []; // one point per day, used for the 7 check-in circles
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Load the summary and the 7-day data at the same time
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MoodService.instance.getSummary(),
        MoodService.instance.getChart(7),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as WeeklySummary;
        _days = results[1] as List<ChartPoint>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -1 = no tab selected (this page is opened from History)
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _header(),
              const SizedBox(height: 8),
              ..._body(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Back arrow + logo + "Your Week" ----------
  Widget _header() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 100),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 120, left: 8),
          child: Text(
            'Your Week',
            style: AppTextStyles.heading.copyWith(fontSize: 38),
          ),
        ),
      ],
    );
  }

  // ---------- Loading / error / empty / summary ----------
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

    final s = _summary!;
    final range =
        '${DateFormat('d MMM').format(s.startDate)} – ${DateFormat('d MMM').format(s.endDate)}';

    // No moods in the last 7 days
    if (s.totalEntries == 0) {
      return [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(range, style: AppTextStyles.subtitle),
        ),
        const SizedBox(height: 50),
        const Icon(Icons.eco_outlined, size: 48, color: AppColors.mediumGreen),
        const SizedBox(height: 12),
        Text(
          'No moods logged this week yet.\nYour summary will appear here 🌿',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false),
            child: const Text('Log a mood'),
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(range, style: AppTextStyles.subtitle),
      ),
      const SizedBox(height: 16),
      _weekDots(),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.edit_note,
              '${s.totalEntries}',
              s.totalEntries == 1 ? 'entry' : 'entries',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              Icons.calendar_today_outlined,
              '${s.daysLogged}/7',
              'days logged',
            ),
          ),
        ],
      ),
      if (s.topMood != null) ...[
        const SizedBox(height: 16),
        _topMoodCard(s),
      ],
      if (s.topTrigger != null) ...[
        const SizedBox(height: 16),
        _topTriggerCard(s),
      ],
      const SizedBox(height: 16),
      _tipCard(s),
      const SizedBox(height: 24),
      Center(
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.moodChart),
          icon: const Icon(Icons.show_chart, size: 22),
          label: const Text('View your mood chart'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkGreen,
            backgroundColor: const Color(0xFFEAF3DC),
            side: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            textStyle: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  // ---------- 7 circles: green tick = mood logged that day ----------
  Widget _weekDots() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check-ins this week', style: _titleStyle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _days.map((p) {
              final logged = p.count > 0;
              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: logged ? AppColors.primaryGreen : Colors.white,
                      border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
                    ),
                    child: logged
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('E').format(p.date),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.darkGreen),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Small number card ("5 entries", "3/7 days logged") ----------
  Widget _statCard(IconData icon, String value, String label) {
    return _card(
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.heading.copyWith(fontSize: 26)),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.mediumGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Most common mood ----------
  Widget _topMoodCard(WeeklySummary s) {
    final mood = AppMoods.byKey(s.topMood!);
    return _card(
      child: Row(
        children: [
          MoodEmoji(mood: mood, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Most common mood', style: _titleStyle),
                const SizedBox(height: 2),
                Text(mood.label, style: AppTextStyles.heading.copyWith(fontSize: 24)),
                Text(
                  _daysText(s.topMoodDays),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.mediumGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Most common trigger ----------
  Widget _topTriggerCard(WeeklySummary s) {
    final trigger = AppTriggers.byKey(s.topTrigger!);
    return _card(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3DC),
              shape: BoxShape.circle,
            ),
            child: Icon(trigger.icon, size: 28, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Most common trigger', style: _titleStyle),
                const SizedBox(height: 2),
                Text(trigger.label, style: AppTextStyles.heading.copyWith(fontSize: 24)),
                Text(
                  _daysText(s.topTriggerDays),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.mediumGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Encouraging tip ----------
  Widget _tipCard(WeeklySummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _tip(s),
              style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _tip(WeeklySummary s) {
    final String consistency;
    if (s.daysLogged >= 5) {
      consistency = 'Great consistency! You checked in on ${s.daysLogged} of 7 days.';
    } else if (s.daysLogged >= 3) {
      consistency = 'Nice work. Checking in a few more days will show clearer patterns.';
    } else {
      consistency = 'A good start. Try logging your mood a little each day.';
    }

    if (s.topTrigger == null) return consistency;
    final trigger = AppTriggers.byKey(s.topTrigger!).label;
    return '$consistency\n\n$trigger came up most often. When it does, '
        'try a short Instant Calm breathing exercise.';
  }

  // ---------- Small helpers ----------
  String _daysText(int days) => '$days ${days == 1 ? 'day' : 'days'} this week';

  TextStyle get _titleStyle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
      );

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: child,
    );
  }
}