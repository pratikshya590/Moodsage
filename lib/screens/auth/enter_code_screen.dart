import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/recovery_service.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/primary_button.dart';

/// "Check your Email": the user types the 6-digit code from the email.
class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  static const _length = 6;
  final _ctrls = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

  String? _email;
  bool _verifying = false;
  bool _resending = false;
  int _resendIn = 60; // seconds until "Resend code" can be used again
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] is String) _email = args['email'] as String;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  // Moves to the next box after typing, back after deleting,
  // and spreads a pasted 6-digit code across all boxes.
  void _onChanged(int i, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < _length; j++) {
        _ctrls[j].text = j < digits.length ? digits[j] : '';
      }
      final next = digits.length.clamp(0, _length - 1);
      _nodes[next].requestFocus();
    } else if (value.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
    if (_code.length == _length) _verify();
  }

  Future<void> _verify() async {
    if (_email == null) {
      _showMessage('Please start again from Forgot Password.', error: true);
      return;
    }
    if (_code.length < _length) {
      _showMessage('Please enter all 6 digits', error: true);
      return;
    }
    if (_verifying) return;

    setState(() => _verifying = true);
    try {
      final token = await RecoveryService.instance.verifyCode(_email!, _code);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.resetOption,
        arguments: {'email': _email, 'resetToken': token},
      );
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
      for (final c in _ctrls) {
        c.clear();
      }
      _nodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_email == null || _resendIn > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await RecoveryService.instance.sendCode(_email!);
      if (!mounted) return;
      _showMessage('A new code has been sent.');
      _startResendTimer();
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              AuthHeader(
                title: 'Check your Email',
                subtitle: _email == null
                    ? 'Enter the 6-digit code we sent you.'
                    : 'Enter the 6-digit code we sent to\n$_email',
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_length, _codeBox),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 280,
                child: PrimaryButton(
                  text: 'Verify',
                  onPressed: _verify,
                  isLoading: _verifying,
                  showArrow: false,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text("Didn't get it?  ",
                      style: AppTextStyles.subtitle.copyWith(fontSize: 16)),
                  GestureDetector(
                    onTap: _resend,
                    child: Text(
                      _resendIn > 0 ? 'Resend code in ${_resendIn}s' : 'Resend code',
                      style: AppTextStyles.link.copyWith(
                        fontSize: 16,
                        color: _resendIn > 0 ? AppColors.greyText : AppColors.linkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeBox(int i) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        autofocus: i == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
        onChanged: (v) => _onChanged(i, v),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          fillColor: const Color(0xFFF9F9F9),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGreenBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
        ),
      ),
    );
  }
}