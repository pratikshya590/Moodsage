import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/recovery_service.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/primary_button.dart';

/// "Create a new Password": opened from Reset Option (receives the reset token).
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['resetToken'] is String) {
      _token = args['resetToken'] as String;
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) {
      _showMessage('Your reset session has expired. Please start again.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await RecoveryService.instance.resetPassword(_token!, _passwordCtrl.text);

      // Sign out any old session, then log in with the new password
      await AuthService.instance.logOut();
      if (!mounted) return;
      _showMessage('Password updated. Please log in with your new password.');
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AuthHeader(
                  title: 'Create a new Password',
                  subtitle: 'Choose a strong password to keep your account safe',
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a new password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _hideConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _reset(),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hideConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 280,
                  child: PrimaryButton(
                    text: 'Reset Password',
                    onPressed: _reset,
                    isLoading: _saving,
                    showArrow: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}