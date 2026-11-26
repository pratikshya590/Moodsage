import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/moods.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/mood_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/primary_button.dart';

// What Helped screen. Owner: Deepsuma Dhakal (Person C)
// Opened right after saving a mood on Home (and from Entry Detail) with the entry id:
//   Navigator.pushNamed(context, AppRoutes.whatHelped, arguments: entry.id);
// After Submit (or Skip) it continues to the Suggestions screen.
class WhatHelpedScreen extends StatefulWidget {
  const WhatHelpedScreen({super.key});

  @override
  State<WhatHelpedScreen> createState() => _WhatHelpedScreenState();
}

class _WhatHelpedScreenState extends State<WhatHelpedScreen> {
  // Colours from the Figma design
  static const _tileFill = Color(0xFFE3EFCF); // light green tiles and pill
  static const _iconCircle = Color(0xFFE9ECC8); // circle behind each icon
  static const _emptyCircle = Color(0xFFDCD9C6); // not-ticked circle
  static const _cream = Color(0xFFF1F4EA); // "Skip for now" button

  final _noteCtrl = TextEditingController();
  final Set<String> _selected = {}; // keys of the ticked options, e.g. 'music'
  bool _started = false; // makes sure we read the id only once
  String? _id;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // The entry id sent by Home (or Entry Detail)
    final args = ModalRoute.of(context)?.settings.arguments;
    _id = args is String ? args : null;
    if (_id != null) _prefill();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // If this entry already has answers (e.g. opened from Entry Detail), tick them
  Future<void> _prefill() async {
    try {
      final entry = await MoodService.instance.getEntry(_id!);
      if (!mounted) return;
      setState(() {
        _selected.addAll(entry.whatHelped);
        if (_noteCtrl.text.isEmpty) _noteCtrl.text = entry.helpedNote;
      });
    } catch (_) {
      // Not important: the user can still choose options
    }
  }

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  // Save the ticked options + note for this entry
  Future<void> _submit() async {
    if (_selected.isEmpty && _noteCtrl.text.trim().isEmpty) {
      _showMessage('Choose at least one option, or tap "Skip for now".', error: true);
      return;
    }
    if (_id == null) {
      _showMessage('Entry not found. Please save your mood again.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      // Keep the same order as on screen
      final keys = AppHelped.all
          .where((h) => _selected.contains(h.key))
          .map((h) => h.key)
          .toList();

      await MoodService.instance.saveWhatHelped(_id!, keys, _noteCtrl.text.trim());
      if (!mounted) return;
      _showMessage('Saved. Thank you for reflecting 🌿');
      _goToSuggestions();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Next screen: personalised suggestions for this entry
  void _goToSuggestions() {
    Navigator.pushReplacementNamed(context, AppRoutes.suggestions, arguments: _id);
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -1 = no tab selected (this page is part of the "log a mood" flow)
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _header(),
            const SizedBox(height: 18),
            _optionsCard(),
            const SizedBox(height: 22),
            _noteCard(),
            const SizedBox(height: 22),
            Center(
              child: SizedBox(
                width: 290,
                child: PrimaryButton(
                  text: 'Submit',
                  onPressed: _submit,
                  isLoading: _saving,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(child: _skipButton()),
          ],
        ),
      ),
    );
  }

  // ---------- Back arrow + logo + title + subtitle ----------
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
          padding: const EdgeInsets.only(top: 110, left: 84),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What Helped you\nfeel better?',
                style: AppTextStyles.heading.copyWith(fontSize: 34, height: 1.15),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us what helped, so we can personalize your support over time.',
                style: AppTextStyles.subtitle.copyWith(fontSize: 15, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Card: "What Helped?" pill + 6 tiles ----------
  Widget _optionsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _tileFill,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.lightGreenBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco, size: 20, color: AppColors.mediumGreen),
                    const SizedBox(width: 6),
                    Text(
                      'What Helped?',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '(Select all that apply)',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.greyText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: AppHelped.all.map((h) => _optionTile(h, width)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // One tile: round icon, label, tick circle on the right
  Widget _optionTile(HelpedOption option, double width) {
    final selected = _selected.contains(option.key);

    return GestureDetector(
      onTap: _saving ? null : () => _toggle(option.key),
      child: Container(
        width: width,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _tileFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.mediumGreen : AppColors.lightGreenBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconCircle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lightGreenBorder),
              ),
              child: Icon(option.icon, size: 20, color: Colors.black),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.15,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _tickCircle(selected),
          ],
        ),
      ),
    );
  }

  Widget _tickCircle(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.mediumGreen : _emptyCircle,
        border: Border.all(
          color: selected ? AppColors.mediumGreen : const Color(0xFFC8C4B0),
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }

  // ---------- Card: "Want to add anything?" + note ----------
  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_outlined, size: 24, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Want to add anything?',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 2),
            child: Text(
              'You can type a short note (optional)',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.greyText),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLength: 500,
            minLines: 1,
            maxLines: 3,
            enabled: !_saving,
            decoration: InputDecoration(
              hintText: "e.g. A friend's call really cheered me up....",
              counterText: '',
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFF4E6B2E), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- "Skip for now / Go to Personalized suggestions" ----------
  Widget _skipButton() {
    return SizedBox(
      width: 290,
      child: OutlinedButton(
        onPressed: _saving ? null : _goToSuggestions,
        style: OutlinedButton.styleFrom(
          backgroundColor: _cream,
          side: const BorderSide(color: Color(0xFF4E6B2E), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Column(
          children: [
            Text(
              'Skip for now',
              style: AppTextStyles.heading.copyWith(fontSize: 20, color: Colors.black),
            ),
            Text(
              'Go to Personalized suggestions',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
    );
  }
}