import 'package:flutter/foundation.dart';

class ApiConfig {
  // true  = use the backend running on this laptop (npm run dev)
  // false = use the deployed backend on Render (works on any phone)
  static const bool useLocalBackend = false;

  static const String _renderUrl = 'https://moodsage-backend.onrender.com/api';

  static String get baseUrl {
    if (!useLocalBackend) return _renderUrl;
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api'; // Android emulator → laptop
  }
}