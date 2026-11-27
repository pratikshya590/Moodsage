import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/mood_service.dart';
import '../../services/reminder_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';

// Settings screen. Owner: Kripa K.C (Person B)
// Daily reminder (on/off + time), Change PIN, Log out, Reset app data.
// The daily reminder is a local notification (ReminderService, added by Pratikshya).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Colours from the Figma design
  static const _greenCircle = Color(0xFFC9DDB0);
  static const _timeChip = Color(0xFFC9DDB0);
  static const _resetFill = Color(0xFFEBE8B0);
  static const _resetBorder = Color(0xFFD9686A);
  static const _pinkCircle = Color(0xFFF2CFCF);
  static const _red = Color(0xFFD32F2F);

  // Saved on the phone by ReminderService (stays after closing the app)
  bool _reminderOn = ReminderService.instance.enabled;
  TimeOfDay _reminderTime = ReminderService.instance.time;

  bool _busy = false; // true while resetting data or logging out

  // ---------- Daily reminder ----------

  Future<void> _toggleReminder(bool on) async {
    final active = await ReminderService.instance.update(on: on, at: _reminderTime);
    if (!mounted) return;
    setState(() => _reminderOn = active);
    _showReminderMessage(on: on, active: active);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null || !mounted) return;
    final active = await ReminderService.instance.update(on: true, at: picked);
    if (!mounted) return;
    setState(() {
      _reminderTime = picked;
      _reminderOn = active;
    });
    _showReminderMessage(on: true, active: active);
  }

  void _showReminderMessage({required bool on, required bool active}) {
    if (!on) {
      _showMessage('Daily reminder off');
    } else if (!ReminderService.instance.supported) {
      _showMessage('Saved. Reminders work in the Android app.');
    } else if (active) {
      _showMessage('Daily reminder set for ${_reminderTime.format(context)}');
    } else {
      _showMessage('Please allow notifications for Moodsage in your phone settings.',
          error: true);
    }
  }

  // ---------- Other actions ----------

  Future<void> _openChangePin() async {
    // No reset token = "Settings mode": saves the new PIN and comes back here
    await Navigator.pushNamed(context, AppRoutes.setNewPin);
  }

  Future<void> _confirmLogout() async {
    final ok = await _confirmDialog(
      title: 'Log out?',
      message: 'You will need your email and password to log in again.',
      action: 'Log out',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    await AuthService.instance.logOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  Future<void> _confirmReset() async {
    final ok = await _confirmDialog(
      title: 'Reset app data?',
      message: 'All your mood entries will be deleted permanently. '
          'Your account, name and PIN will stay.',
      action: 'Delete all',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await MoodService.instance.deleteAllEntries();
      if (!mounted) return;
      _showMessage('All your mood entries have been deleted.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not reset your data. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Yes/No popup, returns true if the user pressed the red button
  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primaryGreen,
      ),
    );
  }

  // ---------- Layout ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: LeafBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _header(),
            const SizedBox(height: 22),
            _reminderCard(),
            const SizedBox(height: 28),
            _rowCard(
              icon: Icons.lock_outline,
              title: 'Change PIN',
              subtitle: 'Update your 4 digit PIN.',
              onTap: _busy ? null : _openChangePin,
            ),
            const SizedBox(height: 28),
            _rowCard(
              icon: Icons.logout,
              title: 'Log out',
              subtitle: 'Sign out of your account.',
              onTap: _busy ? null : _confirmLogout,
            ),
            const SizedBox(height: 28),
            _resetCard(),
          ],
        ),
      ),
    );
  }

  // Logo + "Settings" + subtitle
  Widget _header() {
    return Stack(
      children: [
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 100),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 130, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: AppTextStyles.heading.copyWith(fontSize: 40)),
              const SizedBox(height: 4),
              Text(
                'Manage your app preferences\nand account settings.',
                style: AppTextStyles.subtitle.copyWith(fontSize: 15, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Daily reminder: toggle + time chip ----------
  Widget _reminderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconCircle(Icons.notifications_none, _greenCircle),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily reminder', style: _titleStyle),
                const SizedBox(height: 6),
                Text('Get a gentle nudge to check in with your mood.', style: _subtitleStyle),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: _reminderOn,
                onChanged: _toggleReminder,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.darkGreen,
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickTime,
                child: Opacity(
                  opacity: _reminderOn ? 1 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _timeChip,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 18, color: AppColors.darkGreen),
                        const SizedBox(width: 6),
                        Text(
                          _reminderTime.format(context),
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkGreen),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.darkGreen),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Change PIN / Log out rows ----------
  Widget _rowCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF9F9F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              _iconCircle(icon, _greenCircle),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _titleStyle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: _subtitleStyle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 30, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Yellow "Reset app data" card ----------
  Widget _resetCard() {
    return Material(
      color: _resetFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: _resetBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _busy ? null : _confirmReset,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              _iconCircle(Icons.delete_outline, _pinkCircle, iconColor: _red),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reset app data', style: _titleStyle.copyWith(color: _red)),
                    const SizedBox(height: 4),
                    Text(
                      'This will delete all your mood entries and reset the app.',
                      style: _subtitleStyle.copyWith(color: _red),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 30, color: _red),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Small helpers ----------
  TextStyle get _titleStyle => AppTextStyles.heading.copyWith(fontSize: 22);

  TextStyle get _subtitleStyle =>
      GoogleFonts.inter(fontSize: 14, height: 1.3, color: AppColors.mediumGreen);

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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
    );
  }
}