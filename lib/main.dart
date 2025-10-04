import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const V2VSafetyApp());
}

class V2VSafetyApp extends StatelessWidget {
  const V2VSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'ORBITRIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
