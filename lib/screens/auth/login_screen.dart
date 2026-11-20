import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // 1. Log in with Firebase Authentication
      await AuthService.instance.logIn(_emailCtrl.text, _passwordCtrl.text);

      // 2. Get the profile from the Node.js backend
      //    (create it if it is missing, e.g. sign up was interrupted)
      UserProfile profile;
      try {
        profile = await ProfileService.instance.getProfile();
      } on ApiException catch (e) {
        if (e.message == 'Profile not found') {
          profile = await ProfileService.instance.createProfile();
        } else {
          rethrow;
        }
      }

      // 3. Has a PIN → App Lock. No PIN yet → PIN Setup.
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        profile.hasPin ? AppRoutes.appLock : AppRoutes.pinSetup,
        (route) => false,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) return 'Please enter a valid email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const AppLogo(height: 150),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log in to continue your journey',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _logIn(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your password'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // "Forgot Password?"
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                      ),
                      child: Text('Forgot Password?', style: AppTextStyles.link),
                    ),
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: 280,
                    child: PrimaryButton(
                      text: 'Log in',
                      onPressed: _logIn,
                      isLoading: _loading,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "Don't have an account? Sign up"
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?  ",
                        style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.signUp,
                        ),
                        child: Text(
                          'Sign up',
                          style: AppTextStyles.link.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}