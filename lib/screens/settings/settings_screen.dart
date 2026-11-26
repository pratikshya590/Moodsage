import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/mood_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';

// Settings screen. Owner: Kripa K.C (Person B)
// Profile, change PIN, reset app data, about/privacy and log out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;
  Uint8List? _photo; // profile photo decoded from the saved text (base64)
  bool _loading = true;
  bool _busy = false; // true while resetting data or logging out
  String? _error;

  static const _privacyUrl = 'https://moodsage-backend.onrender.com/privacy';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Get the logged-in user's profile (name, email, photo)
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ProfileService.instance.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _photo = _decodePhoto(profile.photoUrl);
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

  // The photo is saved as "data:image/jpeg;base64,...." → turn it back into bytes
  Uint8List? _decodePhoto(String? url) {
    if (url == null || !url.startsWith('data:')) return null;
    final comma = url.indexOf(',');
    if (comma == -1) return null;
    try {
      return base64Decode(url.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  // ---------- Actions ----------

  Future<void> _openChangePin() async {
    // No reset token = "Settings mode": saves the new PIN and comes back here
    await Navigator.pushNamed(context, AppRoutes.setNewPin);
  }

  void _openEditProfile() {
    Navigator.pushNamed(context, AppRoutes.personalizeProfile);
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

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Moodsage',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'Student project – University of Bedfordshire (CIS099-2)',
      children: const [
        SizedBox(height: 12),
        Text(
          'Track your mood, notice what affects it, and find quick ways '
          'to feel calmer.\n\nMoodsage is not a medical service and does '
          'not replace professional help.',
        ),
      ],
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Your moods are private: only you can see them.\n'
              '• Your PIN is stored securely as a hash, never as plain numbers.\n'
              '• We do not sell or share your data.\n\n'
              'Full privacy policy:',
            ),
            SizedBox(height: 6),
            SelectableText(_privacyUrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  // Logo + "Settings"
  Widget _header() {
    return Stack(
      children: [
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 100),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 110, left: 8),
          child: Text(
            'Settings',
            style: AppTextStyles.heading.copyWith(fontSize: 38),
          ),
        ),
      ],
    );
  }

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

    return [
      _profileCard(),
      const SizedBox(height: 20),
      _sectionLabel('Account'),
      _group([
        _tile(Icons.person_outline, 'Edit name & photo', onTap: _openEditProfile),
        _tile(Icons.lock_outline, 'Change PIN', onTap: _openChangePin),
      ]),
      const SizedBox(height: 20),
      _sectionLabel('Your data'),
      _group([
        _tile(
          Icons.delete_sweep_outlined,
          'Reset app data',
          subtitle: 'Delete all your mood entries',
          color: AppColors.error,
          onTap: _busy ? null : _confirmReset,
        ),
      ]),
      const SizedBox(height: 20),
      _sectionLabel('About'),
      _group([
        _tile(Icons.info_outline, 'About Moodsage', onTap: _showAbout),
        _tile(Icons.privacy_tip_outlined, 'Privacy', onTap: _showPrivacy),
      ]),
      const SizedBox(height: 28),
      Center(
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _confirmLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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

  // Photo (or first letter) + name + email
  Widget _profileCard() {
    final profile = _profile!;
    final name = (profile.name == null || profile.name!.trim().isEmpty)
        ? 'No name yet'
        : profile.name!;
    final letter = name == 'No name yet' ? '?' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFEAF3DC),
            backgroundImage: _photo != null ? MemoryImage(_photo!) : null,
            child: _photo == null
                ? Text(
                    letter,
                    style: AppTextStyles.heading.copyWith(fontSize: 28),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading.copyWith(fontSize: 24),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.mediumGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.mediumGreen,
        ),
      ),
    );
  }

  // A rounded card holding one or more rows, with lines between them
  Widget _group(List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i < tiles.length - 1) {
        children.add(const Divider(height: 1, color: AppColors.lightGreenBorder));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _tile(
    IconData icon,
    String title, {
    String? subtitle,
    Color color = AppColors.darkGreen,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.greyText,
              ),
            ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
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