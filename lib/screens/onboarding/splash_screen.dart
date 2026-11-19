import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

// Splash screen. Owner: Person B
// TODO: replace this placeholder with the real design from Figma.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Splash',
      owner: 'Person B',
    );
  }
}
