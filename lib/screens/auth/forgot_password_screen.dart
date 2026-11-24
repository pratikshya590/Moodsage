import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/recovery_service.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/primary_button.dart';

/// "Reset your access": the user types their email and gets a 6-digit code.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim().toLowerCase();

    setState(() => _sending = true);
    try {
      await RecoveryService.instance.sendCode(email);
      if (!mounted) return;
      _showMessage('If an account exists for this email, a code has been sent.');
      Navigator.pushNamed(context, AppRoutes.enterCode, arguments: {'email': email});
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Please enter a valid email';
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
                  title: 'Reset your access',
                  subtitle: "We'll email you a 6-digit code",
                ),
                const SizedBox(height: 36),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendCode(),
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 280,
                  child: PrimaryButton(
                    text: 'Send Code',
                    onPressed: _sendCode,
                    isLoading: _sending,
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