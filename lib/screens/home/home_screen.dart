import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/moods.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/mood_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/mood_emoji.dart';
import '../../widgets/primary_button.dart';

// Colours used on this screen
const _darkText = Color(0xFF2B2B2B);   // small text (dark, easy to read)
const _tileColor = Color(0xFFEAF3DC);  // Instant Calm / Deep Sleep boxes (light green)
const _tileBorder = Color(0xFFC5DE9B); // soft green border for the boxes

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _noteCtrl = TextEditingController();
  String? _name;
  String? _selectedMood;    // e.g. 'happy'
  String? _selectedTrigger; // e.g. 'work'
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      if (mounted) setState(() => _name = profile.name);
    } catch (_) {
      // Not important: the greeting just says "Hello, there."
    }
  }

  // Tap 3: save the mood through the backend
  Future<void> _save() async {
    if (_selectedMood == null) {
      _showMessage("Please choose how you're feeling", error: true);
      return;
    }
    if (_selectedTrigger == null) {
      _showMessage("Please choose what's behind it", error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final entry = await MoodService.instance.saveMood(
        mood: _selectedMood!,
        trigger: _selectedTrigger!,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;

      _showMessage('Mood saved 🌿');
      setState(() {
        _selectedMood = null;
        _selectedTrigger = null;
        _noteCtrl.clear();
      });

      // Next: "What helped you feel better?" for this entry
      Navigator.pushNamed(context, AppRoutes.whatHelped, arguments: entry.id);
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primaryGreen,
      ),
    );
  }

  // Serif heading used for card titles (natural weight, looks clean)
  TextStyle _cardTitle(double size) => GoogleFonts.dmSerifDisplay(
        fontSize: size,
        color: Colors.black,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: LeafBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 16),
              _moodCard(),
              const SizedBox(height: 24),
              _supportCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- "Hello, Prati." + logo ----------
  Widget _header() {
    return Stack(
      children: [
        // Logo in the top-right corner
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 100),
        ),

        // Greeting below the logo, using the full width
        Padding(
          padding: const EdgeInsets.only(top: 95, left: 50, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _name == null || _name!.isEmpty
                      ? 'Hello, there.'
                      : 'Hello, $_name.',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 40,
                    height: 1.1,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Small steps towards a calmer,\n happier you.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 17,
                  height: 1.25,
                  color: const Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Rounded card container ----------
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: child,
    );
  }

  // ---------- "How are you feeling?" card ----------
  Widget _moodCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling?', style: _cardTitle(26)),
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 16),

          // Tap 1: mood
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppMoods.all.map(_moodButton).toList(),
          ),
          const SizedBox(height: 20),

          Text("What's behind it?", style: _cardTitle(24)),
          const SizedBox(height: 12),

          // Tap 2: trigger (3 per row)
          LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: AppTriggers.all
                    .map((t) => _triggerChip(t, chipWidth))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),

          // Optional note
          TextField(
            controller: _noteCtrl,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              counterText: '',
              fillColor: const Color(0xFFF8F4F4),
              prefixIcon: const Icon(Icons.edit_outlined),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.placeholder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tap 3: save
          PrimaryButton(
            text: "Save today's Mood",
            onPressed: _save,
            isLoading: _saving,
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _moodButton(MoodOption mood) {
    final selected = _selectedMood == mood.key;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = mood.key),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primaryGreen : Colors.transparent,
                width: 3,
              ),
            ),
            child: MoodEmoji(mood: mood, size: 46),
          ),
          const SizedBox(height: 4),
          Text(
            mood.label,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: selected ? AppColors.darkGreen : _darkText,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _triggerChip(TriggerOption trigger, double width) {
    final selected = _selectedTrigger == trigger.key;
    final color = selected ? Colors.white : _darkText;

    return GestureDetector(
      onTap: () => setState(() => _selectedTrigger = trigger.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : const Color(0xFFE3EFCF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : _tileBorder,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trigger.icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                trigger.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- "A Little Support for You" card ----------
  Widget _supportCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A Little Support for You', style: _cardTitle(26)),
          Text(
            'Take a moment for yourself.',
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          _supportTile(
            iconAsset: AppAssets.calmIcon,
            iconBg: const Color(0xFFEDEDB8),
            title: 'Try Instant Calm',
            subtitle: "Take a deep breath. You've got this.",
            metaIcon: Icons.timer_outlined,
            meta: '60 seconds breathing',
            buttonText: 'Start',
            route: AppRoutes.instantCalm,
          ),
          const SizedBox(height: 14),
          _supportTile(
            iconAsset: AppAssets.sleepIcon,
            iconBg: const Color(0xFFC9DDB0),
            title: 'Deep Sleep Sounds',
            subtitle: "Drift into a peaceful night's rest.",
            metaIcon: Icons.music_note,
            meta: 'Rain · Forest · Lo-fi',
            buttonText: 'Listen',
            route: AppRoutes.deepSleep,
          ),
        ],
      ),
    );
  }

  Widget _supportTile({
    required String iconAsset,
    required Color iconBg,
    required String title,
    required String subtitle,
    required IconData metaIcon,
    required String meta,
    required String buttonText,
    required String route,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _tileColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tileBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Round icon from Figma (calm_icon.png / sleep_icon.png)
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Image.asset(iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _cardTitle(19)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(metaIcon, size: 15, color: AppColors.darkGreen),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        meta,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, route),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(buttonText),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}