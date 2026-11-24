import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/leaf_background.dart';

/// "What would you like to reset?": Password or PIN.
/// Opened after the email code is verified (receives the reset token).
class ResetOptionScreen extends StatelessWidget {
  const ResetOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final token = (args is Map) ? args['resetToken'] as String? : null;

    return Scaffold(
      body: LeafBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(
                title: 'What would you like\nto reset?',
                subtitle: 'Choose the option below to get started.',
                align: TextAlign.left,
              ),
              const SizedBox(height: 36),
              if (token == null)
                _expired(context)
              else ...[
                _option(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Reset Password',
                  subtitle: 'Create a new password for your account.',
                  route: AppRoutes.setNewPassword,
                  token: token,
                ),
                const SizedBox(height: 22),
                _option(
                  context,
                  icon: Icons.dialpad,
                  title: 'Reset PIN',
                  subtitle: 'Create a new PIN to unlock the app.',
                  route: AppRoutes.setNewPin,
                  token: token,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required String token,
  }) {
    return Material(
      color: const Color(0xFFF9F9F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.pushReplacementNamed(
          context,
          route,
          arguments: {'resetToken': token},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.grey.shade700),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.greyBody.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 30, color: Colors.grey.shade700),
            ],
          ),
        ),
      ),
    );
  }

  // Shown if the page is opened without a valid reset session
  Widget _expired(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Your reset session has expired.',
            style: AppTextStyles.body.copyWith(fontSize: 16),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.forgotPassword),
            child: const Text('Start again'),
          ),
        ],
      ),
    );
  }
}