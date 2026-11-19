import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';

class MoodsageApp extends StatelessWidget {
  const MoodsageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moodsage',
      theme: AppTheme.light,
      // While building, the app opens on the Dev Menu.
      // Later we change this to AppRoutes.splash.
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
