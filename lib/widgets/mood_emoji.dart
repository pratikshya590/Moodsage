import 'package:flutter/material.dart';
import '../core/constants/moods.dart';

/// Round coloured emoji face for a mood (Home, History, Chart, Detail)
class MoodEmoji extends StatelessWidget {
  final MoodOption mood;
  final double size;

  const MoodEmoji({super.key, required this.mood, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: mood.color, shape: BoxShape.circle),
      child: Icon(mood.icon, size: size, color: mood.iconColor),
    );
  }
}