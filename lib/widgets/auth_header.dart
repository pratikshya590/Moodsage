import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import 'app_logo.dart';

/// Back arrow + big logo + heading + subtitle, used on the recovery screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final TextAlign align;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = true,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final crossAlign =
        align == TextAlign.left ? CrossAxisAlignment.start : CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        SizedBox(
          height: 48,
          child: showBack
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                )
              : null,
        ),
        const Center(child: AppLogo(height: 150)),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: align,
          style: AppTextStyles.heading.copyWith(fontSize: 32, height: 1.2),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: align,
          style: AppTextStyles.subtitle.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}