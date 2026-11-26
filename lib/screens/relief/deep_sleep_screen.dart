import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';

// Deep Sleep Sounds screen. Owner: Deepsuma Dhakal (Person C)
// Opened from Home, Instant Calm and Suggestions. It can receive a sound id
// ('rain', 'nature', 'lofi', 'ocean') to start with that sound.
// Sound files: assets/sounds/<id>.mp3   Pictures: assets/images/sleep_<id>.jpg
// Missing files are handled: a message (sound) or a coloured box (picture).
class DeepSleepScreen extends StatefulWidget {
  const DeepSleepScreen({super.key});

  @override
  State<DeepSleepScreen> createState() => _DeepSleepScreenState();
}

class _Sound {
  final String id;
  final String title;
  final String category; // used by the filter chips
  final String description;
  final IconData icon;
  final Color color;

  const _Sound(this.id, this.title, this.category, this.description, this.icon, this.color);

  String get file => 'sounds/$id.mp3'; // relative to assets/
  String get image => 'assets/images/sleep_$id.jpg';
}

class _DeepSleepScreenState extends State<DeepSleepScreen> {
  static const _sounds = [
    _Sound('rain', 'Rain', 'rain', 'Gentle rain to calm your mind and ease your thoughts.',
        Icons.water_drop, Color(0xFF8FA98A)),
    _Sound('ocean', 'Ocean Waves', 'ocean', 'Soothing waves for a deeper rest.',
        Icons.waves, Color(0xFF3E8E8E)),
    _Sound('forest', 'Forest', 'nature', 'Peaceful nature sounds to relax your mind.',
        Icons.forest, Color(0xFF4E6B3A)),
    _Sound('lofi', 'Lo-fi Music', 'lofi', 'Soft beats for a calm and cozy night.',
        Icons.headphones, Color(0xFFE07A5F)),
  ];

  static const _filters = [
    ('all', 'All'),
    ('nature', 'Nature'),
    ('rain', 'Rain'),
    ('lofi', 'Lo-fi'),
    ('ocean', 'Ocean'),
  ];

  static const _sessionLength = 30 * 60; // 30-minute sleep timer (seconds)

  final AudioPlayer _audio = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  Timer? _timer;

  String _filter = 'all';
  _Sound? _current;
  bool _playing = false;
  bool _repeat = true; // loop the sound until the timer ends
  int _remaining = _sessionLength;
  bool _started = false;
  final Map<String, bool> _hasImage = {}; // which pictures exist in assets/images/

  @override
  void initState() {
    super.initState();
    _checkImages();
    // When repeat is off and the clip ends
    _completeSub = _audio.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _playing = false);
    });
  }

  // Look for each picture once; missing ones show a coloured box instead
  Future<void> _checkImages() async {
    for (final s in _sounds) {
      try {
        await rootBundle.load(s.image);
        _hasImage[s.id] = true;
      } catch (_) {
        _hasImage[s.id] = false;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Sound chosen on Suggestions / Instant Calm ('nature' = Forest)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      final id = args == 'nature' ? 'forest' : args;
      final match = _sounds.where((s) => s.id == id);
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _play(match.first));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completeSub?.cancel();
    _audio.dispose();
    super.dispose();
  }

  // Back arrow: go back if there is a page behind, otherwise go Home
  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    }
  }

  // ---------- Playback ----------

  Future<void> _play(_Sound sound) async {
    final changed = _current?.id != sound.id;
    setState(() {
      _current = sound;
      if (changed) _remaining = _sessionLength;
    });
    try {
      await _audio.stop();
      await _audio.setReleaseMode(_repeat ? ReleaseMode.loop : ReleaseMode.stop);
      await _audio.play(AssetSource(sound.file));
      if (!mounted) return;
      setState(() => _playing = true);
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _playing = false);
      _showMessage('"${sound.title}" sound is not added yet.');
    }
  }

  Future<void> _togglePlay() async {
    final sound = _current;
    if (sound == null) return;
    if (_playing) {
      await _audio.pause();
      _timer?.cancel();
      setState(() => _playing = false);
    } else if (_audio.state == PlayerState.paused) {
      await _audio.resume();
      setState(() => _playing = true);
      _startTimer();
    } else {
      await _play(sound);
    }
  }

  // Counts down the 30-minute sleep timer while playing
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        _audio.stop();
        setState(() {
          _playing = false;
          _remaining = _sessionLength;
        });
        _showMessage('Sleep timer finished. Good night 🌙');
      }
    });
  }

  void _skip(int step) {
    final i = _current == null ? 0 : _sounds.indexWhere((s) => s.id == _current!.id);
    _play(_sounds[(i + step + _sounds.length) % _sounds.length]);
  }

  void _shuffle() {
    final others = _sounds.where((s) => s.id != _current?.id).toList();
    _play(others[Random().nextInt(others.length)]);
  }

  Future<void> _toggleRepeat() async {
    setState(() => _repeat = !_repeat);
    await _audio.setReleaseMode(_repeat ? ReleaseMode.loop : ReleaseMode.stop);
    _showMessage(_repeat ? 'Repeat on' : 'Repeat off');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _format(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  // ---------- Layout ----------

  @override
  Widget build(BuildContext context) {
    final visible = _filter == 'all'
        ? _sounds
        : _sounds.where((s) => s.category == _filter).toList();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _header(),
            const SizedBox(height: 18),
            _banner(),
            const SizedBox(height: 22),
            Text('Choose your Sound',
                style: AppTextStyles.heading.copyWith(fontSize: 24, color: Colors.black)),
            Text('Tap to Play. Let the calm begin.',
                style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
            const SizedBox(height: 14),
            _filterChips(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: visible.map((s) => _soundCard(s, width)).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            if (_current != null) _miniPlayer(_current!),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 24),
            onPressed: _goBack,
          ),
        ),
        const Align(alignment: Alignment.topRight, child: AppLogo(height: 80)),
        Padding(
          padding: const EdgeInsets.only(top: 105),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9DDB0),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGreenBorder),
                ),
                child: const Icon(Icons.bedtime_outlined, size: 38, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deep Sleep Sounds',
                        style: AppTextStyles.heading.copyWith(fontSize: 28)),
                    Text(
                      "Let soothing sounds help you unwind and drift into a peaceful night's sleep",
                      style: AppTextStyles.subtitle.copyWith(fontSize: 14, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Better Sleep, Brighter Tomorrow.',
                style: AppTextStyles.heading.copyWith(fontSize: 21)),
          ),
          const SizedBox(height: 4),
          Text(
            "A good night's sleep helps your mind, mood and energy.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.mediumGreen),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (key, label) = _filters[i];
          final selected = _filter == key;
          return GestureDetector(
            onTap: () => setState(() => _filter = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryGreen : const Color(0xFFC5E39A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _soundCard(_Sound sound, double width) {
    final selected = _current?.id == sound.id;
    return GestureDetector(
      onTap: () => _play(sound),
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.mediumGreen : AppColors.lightGreenBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 70, width: double.infinity, child: _soundImage(sound)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(sound.title,
                            style: AppTextStyles.heading
                                .copyWith(fontSize: 19, color: Colors.black)),
                      ),
                      if (selected && _playing)
                        const Icon(Icons.graphic_eq, size: 20, color: AppColors.mediumGreen),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.mediumGreen),
                      const SizedBox(width: 4),
                      Text('30 min', style: GoogleFonts.inter(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound.description,
                    style: GoogleFonts.inter(
                        fontSize: 12, height: 1.3, color: AppColors.mediumGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Picture, or a coloured box with an icon if the picture is not added yet
  Widget _soundImage(_Sound sound) {
    final placeholder = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sound.color, sound.color.withValues(alpha: 0.6)],
        ),
      ),
      child: Center(child: Icon(sound.icon, size: 34, color: Colors.white70)),
    );

    if (_hasImage[sound.id] != true) return placeholder;

    return Image.asset(
      sound.image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _miniPlayer(_Sound sound) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 48, height: 48, child: _soundImage(sound)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sound.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading.copyWith(fontSize: 17, color: Colors.black)),
                Text(_format(_remaining), style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1 - _remaining / _sessionLength,
                    minHeight: 3,
                    backgroundColor: AppColors.lightGreenBorder,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _control(Icons.shuffle, _shuffle),
                    _control(Icons.fast_rewind, () => _skip(-1)),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_playing ? Icons.pause : Icons.play_arrow,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    _control(Icons.fast_forward, () => _skip(1)),
                    _control(Icons.repeat, _toggleRepeat, active: _repeat),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _control(IconData icon, VoidCallback onTap, {bool active = true}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: active ? Colors.black : AppColors.greyText),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      );
}