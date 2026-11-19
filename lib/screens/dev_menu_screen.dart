import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// TEMPORARY screen for the team: lists every page so you can open
/// any screen while building it. Remove it before the final version.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moodsage – Dev Menu')),
      body: ListView(
        children: [
          _header('Person A (Pratikshya)'),
          _item(context, 'PIN Setup', AppRoutes.pinSetup),
          _item(context, 'App Lock', AppRoutes.appLock),
          _item(context, 'Home', AppRoutes.home),
          _item(context, 'History', AppRoutes.history),
          _item(context, 'Mood Chart', AppRoutes.moodChart),
          _item(context, 'Weekly Summary', AppRoutes.weeklySummary),
          _item(context, 'Forgot Password', AppRoutes.forgotPassword),
          _item(context, 'Enter Code', AppRoutes.enterCode),
          _item(context, 'Reset Option', AppRoutes.resetOption),
          _item(context, 'Set New Password', AppRoutes.setNewPassword),
          _item(context, 'Set New PIN', AppRoutes.setNewPin),
          _header('Person B'),
          _item(context, 'Splash', AppRoutes.splash),
          _item(context, 'Sign Up', AppRoutes.signUp),
          _item(context, 'Login', AppRoutes.login),
          _item(context, 'Personalize Profile', AppRoutes.personalizeProfile),
          _item(context, 'Entry Detail', AppRoutes.entryDetail),
          _item(context, 'Settings', AppRoutes.settings),
          _header('Person C'),
          _item(context, 'What Helped', AppRoutes.whatHelped),
          _item(context, 'Personalized Suggestions', AppRoutes.suggestions),
          _item(context, 'Instant Calm Mode', AppRoutes.instantCalm),
          _item(context, 'Deep Sleep Sounds', AppRoutes.deepSleep),
        ],
      ),
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _item(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.primaryGreen),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
