import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/pin_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/pin_pad.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _padKey = GlobalKey<PinPadState>();
  String? _firstPin; // the PIN typed the first time
  bool _saving = false;

  bool get _confirming => _firstPin != null;

  Future<void> _onSubmit(String pin) async {
    // Step 1: remember the first PIN and ask again
    if (!_confirming) {
      setState(() => _firstPin = pin);
      _padKey.currentState?.clear();
      return;
    }

    // Step 2: the two PINs must match
    if (pin != _firstPin) {
      _showError('PINs do not match. Please try again.');
      setState(() => _firstPin = null);
      _padKey.currentState?.clear();
      return;
    }

    // Step 3: save it through the backend (hashed there)
    setState(() => _saving = true);
    try {
      await PinService.instance.setPin(pin);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.personalizeProfile,
        (route) => false,
      );
    } on ApiException catch (e) {
      _showError(e.message);
      setState(() => _firstPin = null);
      _padKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
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
                  _confirming
                      ? 'Confirm your PIN'
                      : 'Set a PIN to keep\nyour entries Private',
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _confirming
                      ? 'Enter the same 4 digits again'
                      : 'Your thoughts deserve a safe space',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PinPad(key: _padKey, onSubmit: _onSubmit, enabled: !_saving),
                if (_saving) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}