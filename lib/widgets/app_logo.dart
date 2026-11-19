import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';

/// The Moodsage logo (brain circle + name).
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppAssets.logo, height: height);
  }
}
