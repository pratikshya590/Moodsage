import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Big serif headings: "Welcome Back", "Create your Account"
  static final heading = GoogleFonts.dmSerifDisplay(
    fontSize: 34,
    color: AppColors.darkGreen,
  );

  // Green line under headings
  static final subtitle = GoogleFonts.inter(
    fontSize: 16,
    color: AppColors.mediumGreen,
  );

  // Normal text
  static final body = GoogleFonts.inter(
    fontSize: 15,
    color: AppColors.textDark,
  );

  // Grey description text
  static final greyBody = GoogleFonts.inter(
    fontSize: 15,
    color: AppColors.greyText,
  );

  // Text inside green buttons
  static final button = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // "Log in", "Sign up", "Forgot Password?"
  static final link = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.linkGreen,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.linkGreen,
  );

  // Splash: "YOUR MENTAL HEALTH"
  static final splashHeadline = GoogleFonts.bebasNeue(
    fontSize: 46,
    height: 1.05,
    color: AppColors.navy,
  );

  // Splash: "Tap to continue to Sign up"
  static final splashScript = GoogleFonts.cormorantGaramond(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
