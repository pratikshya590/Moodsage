import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/pin_service.dart';
import '../../services/recovery_service.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/pin_pad.dart';
import '../../widgets/primary_button.dart';

/// "Set a New PIN". Used in two ways:
///  1. Recovery: opened from Reset Option with a reset token (forgot PIN)
///  2. Settings → Change PIN: user is logged in, no token needed
class SetNewPinScreen extends StatefulWidget {
  const SetNewPinScreen({super.key});

  @override
  State<SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends State<SetNewPinScreen> {
  final _padKey = GlobalKey<PinPadState>();
  String? _token; // set only in recovery mode
  String? _firstPin; // the PIN typed the first time
  int _typed = 0; // how many digits are entered (to enable Confirm)
  bool _saving = false;

  bool get _confirming => _firstPin != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['resetToken'] is String) {
      _token = args['resetToken'] as String;
    }
  }

  Future<void> _confirm() async {
    final pin = _padKey.currentState?.pin ?? '';
    if (pin.length < 4) {
      _showMessage('Please enter all 4 digits', error: true);
      return;
    }

    // Step 1: remember the first PIN and ask again
    if (!_confirming) {
      setState(() => _firstPin = pin);
      _padKey.currentState?.clear();
      return;
    }

    // Step 2: both PINs must match
    if (pin != _firstPin) {
      _showMessage('PINs do not match. Please try again.', error: true);
      setState(() => _firstPin = null);
      _padKey.currentState?.clear();
      return;
    }

    // Step 3: save (through the backend, hashed with bcrypt)
    setState(() => _saving = true);
    try {
      if (_token != null) {
        await RecoveryService.instance.resetPin(_token!, pin);
      } else {
        await PinService.instance.setPin(pin);
      }
      if (!mounted) return;
      _showMessage('Your PIN has been updated.');

      if (_token == null) {
        // Settings → Change PIN: just go back
        Navigator.pop(context);
      } else {
        // Recovery: logged in → App Lock, otherwise → Login
        final next = AuthService.instance.currentUser != null
            ? AppRoutes.appLock
            : AppRoutes.login;
        Navigator.pushNamedAndRemoveUntil(context, next, (r) => false);
      }
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
      setState(() => _firstPin = null);
      _padKey.currentState?.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              AuthHeader(
                title: _confirming ? 'Confirm your new PIN' : 'Set a New PIN',
                subtitle: _confirming ? 'Enter the same 4 digits again' : 'Create a 4-digit PIN to keep your reflections safe and private.',
              ),
              const SizedBox(height: 32),
              PinPad(
                key: _padKey,
                showOkKey: false,
                enabled: !_saving,
                onChanged: (p) => setState(() => _typed = p.length),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 280,
                child: PrimaryButton(
                  text: 'Confirm',
                  onPressed: _typed == 4 ? _confirm : null,
                  isLoading: _saving,
                  showArrow: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
