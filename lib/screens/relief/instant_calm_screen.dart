import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';

// Instant Calm Mode screen. Owner: Deepsuma Dhakal (Person C)
// Opened from Home's support tiles and from Personalized Suggestions.
// 4 quick tools: guided breathing (60 s), gentle yoga (5 min), calming music, quotes.
class InstantCalmScreen extends StatefulWidget {
  const InstantCalmScreen({super.key});

  @override
  State<InstantCalmScreen> createState() => _InstantCalmScreenState();
}

class _InstantCalmScreenState extends State<InstantCalmScreen> {
  // Colours from the Figma design
  static const _greenCircle = Color(0xFFC9DDB0);
  static const _beigeCircle = Color(0xFFEDEBC0);
  static const _chipFill = Color(0xFFEDEBC0);

  static const _quotes = [
    'Small steps still move you forward.',
    'You are doing better than you think.',
    'Breathe. This moment is enough.',
    'Rest is not giving up. It is taking care of yourself.',
    'Feelings are visitors. Let them come and go.',
    'Be as kind to yourself as you would be to a friend.',
  ];
  int _quoteIndex = 0;

  // ---------- Actions ----------

  void _startBreathing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _BreathingExercisePage()),
    );
  }

  // sound = 'rain', 'nature' or 'lofi' (null = let the user choose)
  void _openMusic([String? sound]) =>
      Navigator.pushNamed(context, AppRoutes.deepSleep, arguments: sound);

  void _showYoga() {
    const steps = [
      ('Easy seated pose, slow breaths', '1 minute'),
      ('Neck and shoulder rolls', '1 minute'),
      ('Cat–cow stretch', '1 minute'),
      ('Seated forward fold', '1 minute'),
      ("Child's pose", '1 minute'),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gentle Yoga · 5 minutes',
                style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              'Move slowly, breathe deeply and stop if anything hurts.',
              style: AppTextStyles.body.copyWith(color: AppColors.mediumGreen),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryGreen,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(steps[i].$1, style: AppTextStyles.body)),
                    Text(
                      steps[i].$2,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('I did it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuote() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: const Icon(Icons.menu_book, color: AppColors.primaryGreen, size: 36),
          content: Text(
            _quotes[_quoteIndex % _quotes.length],
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 22, height: 1.3),
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() => _quoteIndex++),
              child: const Text('Another'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Layout ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _header(),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _toolCard(
                      icon: Icons.air,
                      circle: _greenCircle,
                      title: 'Breathing Exercise',
                      text: 'Follow a guided breathing exercise to relax your body '
                          'and slow your mind.',
                      button: _pillButton('Start', _startBreathing),
                      footer: _duration('60 seconds'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _toolCard(
                      icon: Icons.self_improvement,
                      circle: _beigeCircle,
                      title: 'Gentle Yoga',
                      text: 'Try simple yoga stretches to release tension and '
                          'reconnect with your body.',
                      button: _pillButton('Start', _showYoga),
                      footer: _duration('5 minutes'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _toolCard(
                      icon: Icons.music_note,
                      circle: _beigeCircle,
                      title: 'Calming Music',
                      text: 'Listen to soothing sounds and peaceful music to create '
                          'a relaxing atmosphere.',
                      button: _pillButton('Play Music', _openMusic),
                      footer: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _soundChip('Rain', 'rain'),
                          _soundChip('Nature', 'nature'),
                          _soundChip('Lo-fi', 'lofi'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _toolCard(
                      icon: Icons.menu_book,
                      circle: _greenCircle,
                      title: 'Inspirational Quotes',
                      text: 'Read a comforting thought or gentle affirmation to '
                          'encourage a positive mindset.',
                      button: _pillButton('View Quote', _showQuote),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _footer(),
          ],
        ),
      ),
    );
  }

  // Back arrow + logo + "Instant Calm Mode 😊"
  Widget _header() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 24),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 80),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 130),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Instant Calm Mode',
                  style: AppTextStyles.heading.copyWith(fontSize: 32),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.sentiment_satisfied_alt,
                size: 32,
                color: AppColors.darkGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // One tool card: round icon, title, text, button, small footer
  Widget _toolCard({
    required IconData icon,
    required Color circle,
    required String title,
    required String text,
    required Widget button,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: circle,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightGreenBorder),
            ),
            child: Icon(icon, size: 42, color: Colors.black),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: AppTextStyles.heading.copyWith(fontSize: 20, color: Colors.black),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.3,
              color: AppColors.mediumGreen,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          button,
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _pillButton(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.primaryGreen,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.lightGreenBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 15, color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _duration(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 18, color: AppColors.mediumGreen),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark)),
      ],
    );
  }

  Widget _soundChip(String label, String sound) {
    return GestureDetector(
      onTap: () => _openMusic(sound),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _chipFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGreenBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
      ),
    );
  }

  // "— ♥ —  SMALL STEPS, BIG DIFFERENCE"
  Widget _footer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 1.5, color: AppColors.darkGreen),
            const SizedBox(width: 10),
            const Icon(Icons.favorite, size: 26, color: Color(0xFF7CB342)),
            const SizedBox(width: 10),
            Container(width: 80, height: 1.5, color: AppColors.darkGreen),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'SMALL STEPS,\nBIG DIFFERENCE',
          textAlign: TextAlign.center,
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            height: 1.5,
            color: AppColors.greyText,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Guided 60-second breathing: breathe in 4 s → hold 2 s → breathe out 6 s
// The circle grows while breathing in and shrinks while breathing out.
// ======================================================================
class _BreathingExercisePage extends StatefulWidget {
  const _BreathingExercisePage();

  @override
  State<_BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<_BreathingExercisePage> {
  static const _inhale = 4; // seconds
  static const _hold = 2;
  static const _exhale = 6;
  static const _cycle = _inhale + _hold + _exhale; // 12 s
  static const _total = 60;

  Timer? _timer;
  int _elapsed = 0; // seconds since start
  bool _running = false;
  bool _finished = false;

  int get _secondsLeft => _total - _elapsed;

  // Where we are in the current breath
  String get _phase {
    final t = _elapsed % _cycle;
    if (t < _inhale) return 'Breathe in';
    if (t < _inhale + _hold) return 'Hold';
    return 'Breathe out';
  }

  // Big circle while breathing in / holding, small while breathing out
  double get _circleSize {
    if (!_running && !_finished) return 150;
    if (_finished) return 150;
    return _phase == 'Breathe out' ? 130 : 230;
  }

  // The circle moves at the speed of the current phase
  Duration get _animDuration {
    switch (_phase) {
      case 'Breathe in':
        return const Duration(seconds: _inhale);
      case 'Hold':
        return const Duration(seconds: _hold);
      default:
        return const Duration(seconds: _exhale);
    }
  }

  void _start() {
    if (_finished) {
      _elapsed = 0;
      _finished = false;
    }
    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_elapsed >= _total) {
          _timer?.cancel();
          _running = false;
          _finished = true;
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _elapsed = 0;
      _finished = false;
      _running = false;
    });
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _finished
        ? 'Well done 🌿'
        : (_running || _elapsed > 0)
            ? _phase
            : 'Tap Start';
    final timeLeft =
        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: LeafBackground(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            const SizedBox(height: 10),
            Text('Breathing Exercise', style: AppTextStyles.heading.copyWith(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              'Follow the circle: in for 4, hold for 2, out for 6.',
              style: AppTextStyles.subtitle.copyWith(fontSize: 15),
            ),
            const Spacer(),
            SizedBox(
              height: 260,
              child: Center(
                child: AnimatedContainer(
                  duration: _animDuration,
                  curve: Curves.easeInOut,
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen.withValues(alpha: 0.18),
                    border: Border.all(color: AppColors.primaryGreen, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading.copyWith(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _finished ? 'You finished 60 seconds of calm breathing.' : '$timeLeft left',
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.darkGreen),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_finished)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    )
                  else ...[
                    ElevatedButton(
                      onPressed: _running ? _pause : _start,
                      child: Text(_running ? 'Pause' : (_elapsed > 0 ? 'Resume' : 'Start')),
                    ),
                    if (_elapsed > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _restart,
                        child: const Text('Restart'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}