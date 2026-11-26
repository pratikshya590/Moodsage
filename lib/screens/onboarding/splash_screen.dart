import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_assets.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../services/auth_service.dart';

// Shadow behind white text so it is readable on the picture
const _textShadow = [
  Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
];

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Logged in → App Lock (enter PIN). Not logged in → Sign Up.
  Future<void> _goNext(BuildContext context) async {
    final user = await AuthService.instance.waitForUser();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(
      context,
      user != null ? AppRoutes.appLock : AppRoutes.signUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // The head + mountains picture fills the whole screen
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.splashHero),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        // Dark shade over the bottom part so white text is readable
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.55, 0.75, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: AppLogo(height: 90),
                  ),
                  // Two leaves: left one is mirrored
                  // Two leaves meeting in the middle (left one mirrored)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(4, 0),
                        child: Transform.flip(
                          flipX: true,
                          child: const Icon(
                            Icons.eco,
                            color: AppColors.mediumGreen,
                            size: 36,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-4, 0),
                        child: const Icon(
                          Icons.eco,
                          color: AppColors.mediumGreen,
                          size: 36,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  _headline(),
                  const SizedBox(height: 10),
                  _tagline(),
                  const Spacer(),
                  _features(),
                  const SizedBox(height: 16),
                  _talkBanner(),
                  const SizedBox(height: 12),
                  Text(
                    'SUPPORT    UNDERSTANDING    GROWTH',
                    style: GoogleFonts.oswald(
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Colors.white,
                      shadows: _textShadow,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _beginButton(context),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _goNext(context),
                    child: Text(
                      'Tap to continue to Sign up',
                      style: AppTextStyles.splashScript.copyWith(
                        shadows: _textShadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // "YOUR MENTAL HEALTH / IS AN INVESTMENT, / NOT AN EXPENSE."
  Widget _headline() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text('YOUR MENTAL HEALTH', style: AppTextStyles.splashHeadline),
          Text(
            'IS AN INVESTMENT,',
            style: AppTextStyles.splashHeadline.copyWith(
              color: AppColors.mediumGreen,
            ),
          ),
          Text('NOT AN EXPENSE.', style: AppTextStyles.splashHeadline),
        ],
      ),
    );
  }

  // "—— YOU DESERVE TO FEEL BETTER ——"
  Widget _tagline() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.navy, thickness: 1, endIndent: 10),
        ),
        Text(
          'YOU DESERVE TO FEEL BETTER',
          style: GoogleFonts.oswald(
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF2E2424),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.navy, thickness: 1, indent: 10),
        ),
      ],
    );
  }

  // The 4 round icons: Heal your mind, Find balance...
  Widget _features() {
    final items = <(IconData, String)>[
      (Icons.eco, 'HEAL\nYOUR MIND'),
      (Icons.favorite_border, 'FIND\nBALANCE'),
      (Icons.wb_sunny_outlined, 'REDISCOVER\nYOURSELF'),
      (Icons.accessibility_new, 'LIVE\nFULLY'),
    ];

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(Expanded(child: _feature(items[i].$1, items[i].$2)));
      if (i < items.length - 1) {
        children.add(Container(width: 1, height: 80, color: Colors.white70));
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _feature(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.oswald(
            fontSize: 13,
            height: 1.25,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            shadows: _textShadow,
          ),
        ),
      ],
    );
  }

  // Brush-stroke banner: "LET'S TALK ABOUT IT."
  Widget _talkBanner() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          AppAssets.talkBanner,
          width: double.infinity,
          height: 64,
          fit: BoxFit.fill,
        ),
        Text(
          "LET'S TALK ABOUT IT.",
          style: GoogleFonts.bebasNeue(
            fontSize: 34,
            letterSpacing: 1,
            color: AppColors.darkGreen,
          ),
        ),
      ],
    );
  }

  // Green "LET'S BEGIN →" button (lighter text)
  Widget _beginButton(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 46,
      child: ElevatedButton(
        onPressed: () => _goNext(context),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "LET'S BEGIN",
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
