import 'package:flutter/material.dart';
import '../screens/dev_menu_screen.dart';
import '../screens/auth/enter_code_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/reset_option_screen.dart';
import '../screens/auth/set_new_password_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/history/entry_detail_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/mood_chart_screen.dart';
import '../screens/history/weekly_summary_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/what_helped_screen.dart';
import '../screens/onboarding/personalize_profile_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/pin/app_lock_screen.dart';
import '../screens/pin/pin_setup_screen.dart';
import '../screens/pin/set_new_pin_screen.dart';
import '../screens/relief/deep_sleep_screen.dart';
import '../screens/relief/instant_calm_screen.dart';
import '../screens/relief/suggestions_screen.dart';
import '../screens/settings/settings_screen.dart';

/// All page names in one place.
/// To open a page: Navigator.pushNamed(context, AppRoutes.login);
class AppRoutes {
  // Temporary menu that lists every screen (for testing only)
  static const devMenu = '/dev';

  static const splash = '/splash';
  static const signUp = '/sign-up';
  static const login = '/login';
  static const pinSetup = '/pin-setup';
  static const personalizeProfile = '/personalize-profile';
  static const appLock = '/app-lock';
  static const home = '/home';
  static const whatHelped = '/what-helped';
  static const suggestions = '/suggestions';
  static const instantCalm = '/instant-calm';
  static const deepSleep = '/deep-sleep';
  static const history = '/history';
  static const entryDetail = '/entry-detail';
  static const moodChart = '/mood-chart';
  static const weeklySummary = '/weekly-summary';
  static const settings = '/settings';
  static const forgotPassword = '/forgot-password';
  static const enterCode = '/enter-code';
  static const resetOption = '/reset-option';
  static const setNewPassword = '/set-new-password';
  static const setNewPin = '/set-new-pin';

  static Map<String, WidgetBuilder> get routes => {
        devMenu: (context) => const DevMenuScreen(),
        splash: (context) => const SplashScreen(),
        signUp: (context) => const SignUpScreen(),
        login: (context) => const LoginScreen(),
        pinSetup: (context) => const PinSetupScreen(),
        personalizeProfile: (context) => const PersonalizeProfileScreen(),
        appLock: (context) => const AppLockScreen(),
        home: (context) => const HomeScreen(),
        whatHelped: (context) => const WhatHelpedScreen(),
        suggestions: (context) => const SuggestionsScreen(),
        instantCalm: (context) => const InstantCalmScreen(),
        deepSleep: (context) => const DeepSleepScreen(),
        history: (context) => const HistoryScreen(),
        entryDetail: (context) => const EntryDetailScreen(),
        moodChart: (context) => const MoodChartScreen(),
        weeklySummary: (context) => const WeeklySummaryScreen(),
        settings: (context) => const SettingsScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        enterCode: (context) => const EnterCodeScreen(),
        resetOption: (context) => const ResetOptionScreen(),
        setNewPassword: (context) => const SetNewPasswordScreen(),
        setNewPin: (context) => const SetNewPinScreen(),
      };
}
