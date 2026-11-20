import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// 4 dots + number keypad (1-9, backspace, 0, OK).
/// Used by PIN Setup, App Lock and Set New PIN.
class PinPad extends StatefulWidget {
  final int length;
  final ValueChanged<String> onSubmit;
  final bool enabled;

  const PinPad({
    super.key,
    this.length = 4,
    required this.onSubmit,
    this.enabled = true,
  });

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';

  /// Clears the dots (called by the screen after a wrong PIN etc.)
  void clear() => setState(() => _pin = '');

  void _addDigit(String digit) {
    if (!widget.enabled || _pin.length >= widget.length) return;
    setState(() => _pin += digit);
  }

  void _backspace() {
    if (!widget.enabled || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _ok() {
    if (!widget.enabled) return;
    if (_pin.length < widget.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all ${widget.length} digits')),
      );
      return;
    }
    widget.onSubmit(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(),
        const SizedBox(height: 44),
        _row([_digitKey('1'), _digitKey('2'), _digitKey('3')]),
        const SizedBox(height: 22),
        _row([_digitKey('4'), _digitKey('5'), _digitKey('6')]),
        const SizedBox(height: 22),
        _row([_digitKey('7'), _digitKey('8'), _digitKey('9')]),
        const SizedBox(height: 22),
        _row([_backspaceKey(), _digitKey('0'), _okKey()]),
      ],
    );
  }

  // The 4 circles: filled green when a digit is entered
  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        final filled = i < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.mediumGreen : Colors.transparent,
            border: Border.all(color: AppColors.mediumGreen, width: 3),
          ),
        );
      }),
    );
  }

  Widget _row(List<Widget> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys
          .map((k) => SizedBox(width: 96, child: Center(child: k)))
          .toList(),
    );
  }

  Widget _digitKey(String digit) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.pinBorder, width: 1.5),
    );
    return Material(
      color: AppColors.pinFill,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => _addDigit(digit),
        child: SizedBox(
          width: 56,
          height: 46,
          child: Center(
            child: Text(
              digit,
              style: GoogleFonts.inter(fontSize: 20, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey() {
    return IconButton(
      onPressed: _backspace,
      icon: const Icon(Icons.backspace_outlined, size: 30, color: Colors.black),
    );
  }

  Widget _okKey() {
    return TextButton(
      onPressed: _ok,
      child: Text(
        'OK',
        style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: Colors.black),
      ),
    );
  }
}