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

// Entry Detail screen. Owner: Kripa K.C (Person B)
// Opened from History with the entry id:
//   Navigator.pushNamed(context, AppRoutes.entryDetail, arguments: entry.id);
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
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
      Navigator.pop(context, true); // History reloads when we come back
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
      // -1 = no tab selected (this page is opened from History)
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _header(),
            const SizedBox(height: 16),
            ..._body(),
          ],
        ),
      ),
    );
  }

  // ---------- Back arrow + logo + "Your Entry" ----------
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
            'Your Entry',
            style: AppTextStyles.heading.copyWith(fontSize: 38),
          ),
        ),
      ],
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
    final mood = AppMoods.byKey(entry.mood);
    final trigger = AppTriggers.byKey(entry.trigger);

    return [
      _moodCard(entry, mood),
      const SizedBox(height: 16),
      _section(
        title: "What's behind it?",
        child: Align(
          alignment: Alignment.centerLeft,
          child: _chip(trigger.icon, trigger.label),
        ),
      ),
      const SizedBox(height: 16),
      _section(
        title: 'Your note',
        child: Text(
          entry.note.isEmpty ? 'No note added.' : entry.note,
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            height: 1.4,
            color: entry.note.isEmpty ? AppColors.greyText : AppColors.textDark,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _section(title: 'What helped', child: _whatHelped(entry)),
      const SizedBox(height: 28),
      _deleteButton(),
    ];
  }

  // ---------- Big card: emoji + mood name + date ----------
  Widget _moodCard(MoodEntry entry, MoodOption mood) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          MoodEmoji(mood: mood, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feeling ${mood.label}',
                  style: AppTextStyles.heading.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM y').format(entry.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(entry.createdAt),
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

  // ---------- "What helped" list (or a button to add it) ----------
  Widget _whatHelped(MoodEntry entry) {
    if (entry.whatHelped.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing added yet.',
            style: AppTextStyles.body.copyWith(color: AppColors.greyText),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _openWhatHelped,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add what helped'),
            style: TextButton.styleFrom(foregroundColor: AppColors.linkGreen),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entry.whatHelped.map((key) {
            final option = AppHelped.byKey(key);
            return _chip(option.icon, option.label);
          }).toList(),
        ),
        if (entry.helpedNote.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            entry.helpedNote,
            style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.4),
          ),
        ],
      ],
    );
  }

  // ---------- Red "Delete entry" button ----------
  Widget _deleteButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _deleting ? null : _confirmDelete,
        icon: const Icon(Icons.delete_outline),
        label: Text(_deleting ? 'Deleting...' : 'Delete entry'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: AppTextStyles.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------- Small helpers ----------
  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreenBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.darkGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkGreen),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
    );
  }
}