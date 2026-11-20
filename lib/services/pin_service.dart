import 'api_service.dart';

class PinService {
  PinService._();
  static final instance = PinService._();

  /// Save a new PIN (the backend stores it hashed)
  Future<void> setPin(String pin) async {
    await ApiService.instance.post('/pin', {'pin': pin});
  }

  /// Check a PIN, returns true if correct
  Future<bool> verifyPin(String pin) async {
    final data = await ApiService.instance.post('/pin/verify', {'pin': pin});
    return (data as Map<String, dynamic>)['valid'] == true;
  }
}