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
import '../../widgets/primary_button.dart';

// Weekly Summary screen. Owner: Kripa K.C (Person B)
// "Your Week in Review": days logged, most common mood and most common trigger
// for the last 7 days. Opened from History.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  // Colours from the Figma design
  static const _greenCircle = Color(0xFFC9DDB0);
  static const _beigeCircle = Color(0xFFEDEBC0);
  static const _pinkCard = Color(0xFFFDF2F2);

  WeeklySummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Get this week's summary from the backend
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await MoodService.instance.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  // Back to History (also used by "View full history")
  void _goToHistory() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.history, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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

  // ---------- Back arrow + logo ----------
  Widget _header() {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 24),
              onPressed: _goToHistory,
            ),
          ),
          const Align(
            alignment: Alignment.topRight,
            child: AppLogo(height: 100),
          ),
        ],
      ),
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
        '${DateFormat('MMMM d').format(s.startDate)} – ${DateFormat('MMMM d').format(s.endDate)}';

    final title = [
      Center(
        child: Text(
          'Your Week in Review',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading.copyWith(fontSize: 32),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 24, color: Colors.black),
          const SizedBox(width: 10),
          Text(range, style: AppTextStyles.heading.copyWith(fontSize: 18)),
        ],
      ),
      const SizedBox(height: 26),
    ];

    // No moods in the last 7 days
    if (s.totalEntries == 0) {
      return [
        ...title,
        const SizedBox(height: 20),
        const Icon(Icons.eco_outlined, size: 48, color: AppColors.mediumGreen),
        const SizedBox(height: 12),
        Text(
          'No moods logged this week yet.\nYour review will appear here 🌿',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 260,
            child: PrimaryButton(
              text: 'Log a mood',
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false),
            ),
          ),
        ),
      ];
    }

    return [
      ...title,
      _daysAndMoodCard(s),
      const SizedBox(height: 26),
      _triggerCard(s),
      const SizedBox(height: 44),
      Center(
        child: SizedBox(
          width: double.infinity,
          child: PrimaryButton(text: 'View full history', onPressed: _goToHistory),
        ),
      ),
      const SizedBox(height: 40),
      Text(
        'Small steps still count.\nYou showed up for yourself this week.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 15, height: 1.4, color: const Color(0xFF7A9A4A)),
      ),
    ];
  }

  // ---------- Days logged | Most common mood ----------
  Widget _daysAndMoodCard(WeeklySummary s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: _cardDecoration(const Color(0xFFF9F9F9)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left: days logged
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _iconCircle(Icons.calendar_month_outlined, _greenCircle),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Days logged',
                                style: AppTextStyles.heading.copyWith(fontSize: 18)),
                            Text('${s.daysLogged} / 7',
                                style: AppTextStyles.heading.copyWith(fontSize: 32)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You logged your mood ${s.daysLogged} out of 7 days this week.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.3,
                      color: AppColors.mediumGreen,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 20, thickness: 1, color: Color(0xFF9E9E9E)),
            // Right: most common mood
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most common mood',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 10),
                  if (s.topMood == null)
                    Text('—', style: AppTextStyles.heading.copyWith(fontSize: 22))
                  else
                    Row(
                      children: [
                        MoodEmoji(mood: AppMoods.byKey(s.topMood!), size: 48),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppMoods.byKey(s.topMood!).label,
                                style: AppTextStyles.heading.copyWith(fontSize: 22),
                              ),
                              Text(
                                _daysText(s.topMoodDays),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.mediumGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Most common trigger (pink card) ----------
  Widget _triggerCard(WeeklySummary s) {
    final trigger = s.topTrigger == null ? null : AppTriggers.byKey(s.topTrigger!);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: _cardDecoration(_pinkCard),
      child: Row(
        children: [
          _iconCircle(
            trigger?.icon ?? Icons.bolt,
            _beigeCircle,
            iconColor: const Color(0xFFE5533D),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Most common trigger',
                    style: AppTextStyles.heading.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  trigger?.label ?? '—',
                  style: AppTextStyles.heading.copyWith(fontSize: 32),
                ),
                if (trigger != null)
                  Text(
                    _daysText(s.topTriggerDays),
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.mediumGreen),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Small helpers ----------
  String _daysText(int days) => '$days ${days == 1 ? 'day' : 'days'}';

  Widget _iconCircle(IconData icon, Color color, {Color iconColor = Colors.black}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightGreenBorder),
      ),
      child: Icon(icon, size: 28, color: iconColor),
    );
  }

  BoxDecoration _cardDecoration(Color fill) {
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
    );
  }
}