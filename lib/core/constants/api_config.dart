import 'package:flutter/foundation.dart';

class ApiConfig {
  // Your laptop's Wi-Fi IP address, used when testing on a real Android phone.
  // We will fill this in when we test on Android.
  static const String _laptopIp = '192.168.1.100';

  static String get baseUrl {
    if (kIsWeb) {
      // Running in Chrome on the same laptop as the backend
      return 'http://localhost:3000/api';
    }
    // Running on an Android phone (same Wi-Fi as the laptop)
    return 'http://$_laptopIp:3000/api';
  }
}