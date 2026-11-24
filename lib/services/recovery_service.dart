import 'api_service.dart';

/// Account recovery with a 6-digit email code (Node.js /api/recovery routes).
class RecoveryService {
  RecoveryService._();
  static final instance = RecoveryService._();

  /// Step 1: email a 6-digit code (same reply whether or not the email exists)
  Future<void> sendCode(String email) async {
    await ApiService.instance.post('/recovery/send-code', {'email': email.trim()});
  }

  /// Step 2: check the code; returns a short-lived reset token
  Future<String> verifyCode(String email, String code) async {
    final data = await ApiService.instance.post('/recovery/verify-code', {
      'email': email.trim(),
      'code': code,
    });
    return (data as Map<String, dynamic>)['resetToken'] as String;
  }

  /// Step 3a: set a new password
  Future<void> resetPassword(String resetToken, String newPassword) async {
    await ApiService.instance.post('/recovery/reset-password', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }

  /// Step 3b: set a new PIN
  Future<void> resetPin(String resetToken, String newPin) async {
    await ApiService.instance.post('/recovery/reset-pin', {
      'resetToken': resetToken,
      'newPin': newPin,
    });
  }
}