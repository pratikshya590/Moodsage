import 'package:flutter/foundation.dart';

class ApiConfig {
  // ---- Choose where the backend is ----
  // Android emulator: 10.0.2.2 means "the laptop running the emulator"
  // Real phone on same Wi-Fi: use your laptop's Wi-Fi IP (e.g. 192.168.1.5)
  static const String _androidHost = '10.0.2.2';

  static String get baseUrl {
    if (kIsWeb) {
      // Chrome on the same laptop as the backend
      return 'http://localhost:3000/api';
    }
    // Android emulator or phone
    return 'http://$_androidHost:3000/api';
  }
}