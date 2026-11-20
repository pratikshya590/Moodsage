import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../core/theme/app_colors.dart';

/// Bottom bar: Home | History | Setting
/// currentIndex: 0 = Home, 1 = History, 2 = Setting
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(context, 0, Icons.home_outlined, 'Home', AppRoutes.home),
              _item(context, 1, Icons.history, 'History', AppRoutes.history),
              _item(context, 2, Icons.settings_outlined, 'Setting', AppRoutes.settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String route,
  ) {
    final selected = index == currentIndex;
    final color = Colors.black;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: selected
          ? null
          : () => Navigator.pushNamedAndRemoveUntil(context, route, (r) => false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}