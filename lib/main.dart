import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MoodsageApp());
}

class MoodsageApp extends StatelessWidget {
  const MoodsageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moodsage',
      home: Scaffold(
        body: Center(
          child: Text('Firebase connected ✅', style: TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}
