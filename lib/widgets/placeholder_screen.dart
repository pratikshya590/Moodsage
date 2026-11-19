import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import 'leaf_background.dart';

/// Temporary page shown until a screen is built.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String owner;

  const PlaceholderScreen({super.key, required this.title, required this.owner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: LeafBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.heading, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Owner: $owner', style: AppTextStyles.subtitle),
              const SizedBox(height: 4),
              Text('Coming soon', style: AppTextStyles.greyBody),
            ],
          ),
        ),
      ),
    );
  }
}
