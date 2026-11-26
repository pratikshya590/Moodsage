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
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/mood_emoji.dart';

// Entry Detail screen. Owner: Kripa K.C (Person B)
// Opened from History with the entry id:
//   Navigator.pushNamed(context, AppRoutes.entryDetail, arguments: entry.id);
// Shows date, time, mood, trigger, note and what helped. The entry can be deleted.
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  // Colours from the Figma design
  static const _chipFill = Color(0xFFE6E3E0); // trigger chip
  static const _deleteFill = Color(0xFFF0D9D9); // pink delete button
  static const _deleteBorder = Color(0xFF6B7A4A);

  bool _started = false; // makes sure we read the id only once
  String? _id;
  MoodEntry? _entry;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // The id sent by the History screen
    final args = ModalRoute.of(context)?.settings.arguments;
    _id = args is String ? args : null;

    if (_id == null) {
      _loading = false;
      _error = 'Entry not found.';
    } else {
      _load();
    }
  }

  // Get this one entry from the backend
  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final entry = await MoodService.instance.getEntry(_id!);
      if (!mounted) return;
      setState(() {
        _entry = entry;
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

  // Back if there is a page behind, otherwise go to History
  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.history, (r) => false);
    }
  }

  // Ask first, then delete and go back to History
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This mood entry will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await MoodService.instance.deleteEntry(_entry!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
      _goBack(); // History reloads when we come back
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  // Open "What helped?" for this entry, then reload to show the answer
  Future<void> _openWhatHelped() async {
    await Navigator.pushNamed(context, AppRoutes.whatHelped, arguments: _entry!.id);
    if (mounted) _load(showSpinner: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _header(),
            const SizedBox(height: 24),
            ..._body(),
          ],
        ),
      ),
    );
  }

  // ---------- Back arrow + logo ----------
  Widget _header() {
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 24),
              onPressed: _goBack,
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

  // ---------- Loading / error / the entry ----------
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
        if (_id != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _load(showSpinner: true),
              child: const Text('Try again'),
            ),
          ),
        ],
      ];
    }

    final entry = _entry!;
    return [
      Center(child: _topCard(entry)),
      const SizedBox(height: 22),
      _noteCard(entry),
      const SizedBox(height: 26),
      _whatHelpedCard(entry),
      const SizedBox(height: 36),
      Center(child: _deleteButton()),
    ];
  }

  // ---------- Date + time, emoji, trigger chip ----------
  Widget _topCard(MoodEntry entry) {
    final mood = AppMoods.byKey(entry.mood);
    final trigger = AppTriggers.byKey(entry.trigger);

    return Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                DateFormat('MMM d, y').format(entry.createdAt),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.mediumGreen),
              ),
              Text(
                DateFormat('h:mm a').format(entry.createdAt),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.mediumGreen),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MoodEmoji(mood: mood, size: 50),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _chipFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trigger.icon, size: 20, color: Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      trigger.label,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.darkGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- "Your Note" ----------
  Widget _noteCard(MoodEntry entry) {
    return _section(
      icon: const Icon(Icons.assignment, size: 30, color: Color(0xFF5A5A5A)),
      title: 'Your Note',
      child: Text(
        entry.note.isEmpty ? 'No note added.' : entry.note,
        style: _bodyText.copyWith(
          color: entry.note.isEmpty ? AppColors.greyText : AppColors.mediumGreen,
        ),
      ),
    );
  }

  // ---------- "What helped" (as a sentence) ----------
  Widget _whatHelpedCard(MoodEntry entry) {
    final labels = entry.whatHelped.map((k) => AppHelped.byKey(k).label).toList();
    final hasAnything = labels.isNotEmpty || entry.helpedNote.isNotEmpty;

    return _section(
      icon: const Icon(Icons.favorite_border, size: 26, color: Color(0xFFE53935)),
      title: 'What helped',
      child: hasAnything
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (labels.isNotEmpty) Text('${labels.join(', ')}.', style: _bodyText),
                if (entry.helpedNote.isNotEmpty) ...[
                  if (labels.isNotEmpty) const SizedBox(height: 8),
                  Text(entry.helpedNote, style: _bodyText),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nothing added yet.',
                  style: _bodyText.copyWith(color: AppColors.greyText),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _openWhatHelped,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add what helped'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.linkGreen),
                ),
              ],
            ),
    );
  }

  // ---------- Pink "Delete" button ----------
  Widget _deleteButton() {
    return SizedBox(
      width: 260,
      height: 52,
      child: OutlinedButton(
        onPressed: _deleting ? null : _confirmDelete,
        style: OutlinedButton.styleFrom(
          backgroundColor: _deleteFill,
          side: const BorderSide(color: _deleteBorder, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
            const SizedBox(width: 10),
            Text(
              _deleting ? 'Deleting...' : 'Delete',
              style: AppTextStyles.heading.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Small helpers ----------
  Widget _section({required Widget icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.heading.copyWith(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  TextStyle get _bodyText => GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        letterSpacing: 0.6,
        color: AppColors.mediumGreen,
      );

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
    );
  }
}