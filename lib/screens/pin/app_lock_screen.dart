import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/pin_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/pin_pad.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _padKey = GlobalKey<PinPadState>();
  bool _loading = true;   // loading the profile
  bool _checking = false; // checking the PIN with the backend
  String? _name;
  int _wrongAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Not logged in → go to Login
    final user = await AuthService.instance.waitForUser();
    if (!mounted) return;
    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
      return;
    }

    try {
      final profile = await ProfileService.instance.getProfile();
      if (!mounted) return;

      // Logged in but no PIN yet → go to PIN Setup
      if (!profile.hasPin) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.pinSetup, (r) => false);
        return;
      }

      setState(() {
        _name = profile.name;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    }
  }

  Future<void> _onSubmit(String pin) async {
    setState(() => _checking = true);
    try {
      final correct = await PinService.instance.verifyPin(pin);
      if (!mounted) return;

      if (correct) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        return;
      }

      _wrongAttempts++;
      _padKey.currentState?.clear();
      _showError(
        _wrongAttempts >= 3
            ? 'Wrong PIN. Forgot it? Tap "Forgot PIN?" below.'
            : 'Wrong PIN. Please try again.',
      );
    } on ApiException catch (e) {
      _padKey.currentState?.clear();
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const AppLogo(height: 150),
                const SizedBox(height: 16),
                Text(
                  _name == null ? 'Welcome back' : 'Welcome back, $_name',
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Enter your PIN', style: AppTextStyles.subtitle),
                const SizedBox(height: 32),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else
                  PinPad(
                    key: _padKey,
                    onSubmit: _onSubmit,
                    enabled: !_checking,
                  ),
                if (_checking) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: Text('Forgot PIN?', style: AppTextStyles.link),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}