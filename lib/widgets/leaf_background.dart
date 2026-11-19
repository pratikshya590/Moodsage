import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';

/// White page with the watercolour leaves in the corners.
/// Use it on every screen: body: LeafBackground(child: ...)
class LeafBackground extends StatelessWidget {
  final Widget child;

  const LeafBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage(AppAssets.leafBackground),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
