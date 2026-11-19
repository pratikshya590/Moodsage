import 'package:flutter/material.dart';

/// Big green rounded button with an arrow, e.g. "Log in  →".
/// Shows a spinner instead of the text while isLoading is true.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text),
                if (showArrow) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward),
                ],
              ],
            ),
    );
  }
}
