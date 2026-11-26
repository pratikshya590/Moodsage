import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/mood_entry.dart';
import '../../services/mood_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';

// Personalized Suggestions screen. Owner: Deepsuma Dhakal (Person C)
// Opened after What Helped with the entry id:
//   Navigator.pushReplacementNamed(context, AppRoutes.suggestions, arguments: entryId);
// Uses the entry's mood and trigger to personalise the cards.
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  // Colours from the Figma design
  static const _greenCircle = Color(0xFFDCEBC9);
  static const _beigeCircle = Color(0xFFEDEBC0);
  static const _darkCircle = Color(0xFFC9DDB0);
  static const _chipFill = Color(0xFFEDEBC0);

  bool _started = false; // makes sure we read the id only once
  MoodEntry? _entry; // the mood just logged (null if it could not be loaded)
  bool _tinyDone = false;
  int _quoteIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) _loadEntry(args);
  }

  // Get the mood + trigger of the entry (the screen still works without it)
  Future<void> _loadEntry(String id) async {
    try {
      final entry = await MoodService.instance.getEntry(id);
      if (!mounted) return;
      setState(() => _entry = entry);
    } catch (_) {
      // Not important: general suggestions are shown instead
    }
  }

  // ---------- Personalisation ----------

  // Which card gets the "Recommended for you" tag
  String get _recommended {
    switch (_entry?.mood) {
      case 'angry':
        return 'breathing';
      case 'sad':
      case 'cry':
        return 'quote';
      case 'neutral':
        return 'movement';
      case 'happy':
        return 'tiny';
      default:
        return '';
    }
  }

  // Tiny Action text depends on what is affecting the user
  String get _tinyAction {
    switch (_entry?.trigger) {
      case 'sleep':
        return 'Put your phone away 30 minutes before bed tonight.';
      case 'work':
        return 'Stand up, stretch and look away from the screen for a minute.';
      case 'relationship':
        return 'Send a kind message to someone you trust.';
      case 'money':
        return 'Write down one small thing you can control today.';
      case 'health':
        return 'Drink a glass of water and rest for a few minutes.';
      default:
        return 'Drink a glass of water / step outside for a minute.';
    }
  }

  // Affirmations chosen for the mood
  List<String> get _quotes {
    switch (_entry?.mood) {
      case 'sad':
      case 'cry':
        return const [
          "It's okay to have hard days. You don't have to carry everything at once.",
          'This feeling is real, and it will pass.',
          'Be as kind to yourself as you would be to a good friend.',
        ];
      case 'angry':
        return const [
          'Pause. Breathe. You can choose your next step calmly.',
          "Your feelings are valid. You don't have to act on them right now.",
          'One slow breath at a time is enough.',
        ];
      case 'happy':
        return const [
          'Notice this good moment and let it stay a little longer.',
          'You deserve to feel this way.',
          'Share a little of this joy with someone today.',
        ];
      default:
        return const [
          'Small steps still move you forward.',
          'You are doing better than you think.',
          'Rest is not giving up. It is taking care of yourself.',
        ];
    }
  }

  // ---------- Actions ----------

  void _openInstantCalm() => Navigator.pushNamed(context, AppRoutes.instantCalm);

  // sound = 'rain', 'nature' or 'lofi' (null = let the user choose)
  void _openSounds([String? sound]) =>
      Navigator.pushNamed(context, AppRoutes.deepSleep, arguments: sound);

  void _showStretch() {
    const steps = [
      ('Neck rolls', '30 seconds'),
      ('Shoulder rolls', '30 seconds'),
      ('Reach up and stretch side to side', '1 minute'),
      ('Gentle forward fold', '1 minute'),
      ("Child's pose with slow breathing", '2 minutes'),
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
            Text('5-minute stretch', style: AppTextStyles.heading.copyWith(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              'Move slowly and stop if anything hurts.',
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
        builder: (ctx, setDialogState) {
          final quotes = _quotes;
          final quote = quotes[_quoteIndex % quotes.length];
          return AlertDialog(
            icon: const Icon(Icons.favorite_border, color: AppColors.primaryGreen, size: 36),
            content: Text(
              quote,
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
          );
        },
      ),
    );
  }

  void _markTinyDone() {
    if (_tinyDone) return;
    setState(() => _tinyDone = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Well done! Small actions make a big difference 🌿'),
        backgroundColor: AppColors.primaryGreen,
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
            const SizedBox(height: 22),
            _card(
              id: 'breathing',
              icon: Icons.air,
              circle: _greenCircle,
              title: 'Breathing / Calm',
              subtitle: 'Try a 60 second breathing exercise.',
              action: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pillButton('Start', onTap: _openInstantCalm),
                  const SizedBox(height: 4),
                  Text(
                    'Go to Instant\ncalm Mode',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.mediumGreen),
                  ),
                ],
              ),
            ),
            _card(
              id: 'audio',
              icon: Icons.headphones,
              circle: _beigeCircle,
              title: 'Audio',
              subtitle: 'Listen to a calming sound clip.',
              extra: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _soundChip('Rain', 'rain'),
                  _soundChip('Nature', 'nature'),
                  _soundChip('Lo-fi', 'lofi'),
                ],
              ),
              action: _pillButton('Play', leading: Icons.play_arrow, onTap: _openSounds),
            ),
            _card(
              id: 'movement',
              icon: Icons.self_improvement,
              circle: _darkCircle,
              title: 'Movement',
              subtitle: 'Try a 5-minute stretch or yoga.',
              action: _pillButton('Start Activity', onTap: _showStretch),
            ),
            _card(
              id: 'quote',
              icon: Icons.favorite_border,
              circle: _beigeCircle,
              title: 'Quote / Affirmation',
              subtitle: 'A short comforting thought for this moment.',
              action: _pillButton('View', onTap: _showQuote),
            ),
            _card(
              id: 'tiny',
              icon: Icons.local_drink,
              circle: _darkCircle,
              title: 'Tiny Action',
              subtitle: _tinyAction,
              action: _pillButton(
                _tinyDone ? 'Done ✓' : 'Done',
                leading: _tinyDone ? null : Icons.check,
                showArrow: false,
                onTap: _markTinyDone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Back arrow + logo + headings
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
          padding: const EdgeInsets.only(top: 130, left: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR PERSONALIZED SUPPORT',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  color: AppColors.mediumGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Based on your mood '),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.favorite_border,
                        size: 24,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const TextSpan(text: "\nand what's affecting you,"),
                  ],
                  style: AppTextStyles.heading.copyWith(fontSize: 26, height: 1.25),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'here are a few things you could try',
                style: AppTextStyles.subtitle.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // One suggestion card: round icon, text, button on the right
  Widget _card({
    required String id,
    required IconData icon,
    required Color circle,
    required String title,
    required String subtitle,
    required Widget action,
    Widget? extra,
  }) {
    final recommended = id == _recommended;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: recommended ? AppColors.mediumGreen : AppColors.lightGreenBorder,
            width: recommended ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: circle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lightGreenBorder),
              ),
              child: Icon(icon, size: 28, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommended)
                    Text(
                      '★ Recommended for you',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mediumGreen,
                      ),
                    ),
                  Text(
                    title,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 19,
                      height: 1.15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.3,
                      color: AppColors.mediumGreen,
                    ),
                  ),
                  if (extra != null) ...[
                    const SizedBox(height: 8),
                    extra,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            action,
          ],
        ),
      ),
    );
  }

  // Small green pill button, e.g. "Start →"
  Widget _pillButton(
    String label, {
    required VoidCallback onTap,
    IconData? leading,
    bool showArrow = true,
  }) {
    return Material(
      color: AppColors.primaryGreen,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.lightGreenBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
              if (showArrow) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // "Rain", "Nature", "Lo-fi" chips under Audio
  Widget _soundChip(String label, String sound) {
    return GestureDetector(
      onTap: () => _openSounds(sound),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _chipFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGreenBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
        ),
      ),
    );
  }
}