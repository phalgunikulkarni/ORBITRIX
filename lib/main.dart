import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const V2VSafetyApp());
}

class V2VSafetyApp extends StatelessWidget {
  const V2VSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
