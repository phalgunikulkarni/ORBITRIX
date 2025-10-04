import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ORBITRIX Brand Colors - Premium Gradient Palette
  static const Color primaryBlue = Color(0xFF0B1426);
  static const Color secondaryBlue = Color(0xFF1E3A8A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color neonBlue = Color(0xFF06B6D4);
  
  // Premium Gradient Colors
  static const Color gradientStart = Color(0xFF667EEA);
  static const Color gradientEnd = Color(0xFF764BA2);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color crimsonRed = Color(0xFFEF4444);
  
  // Glassmorphism Colors
  static const Color glassWhite = Color(0x20FFFFFF);
  static const Color glassBlack = Color(0x20000000);
  static const Color glassBlue = Color(0x203B82F6);
  
  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
  
  static const LinearGradient criticalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
  );
  
  static const LinearGradient trafficGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
  );

  // Shadow Definitions
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
  
  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accentBlue.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];

  // Custom Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(accentBlue),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      
      // Custom Color Scheme
      colorScheme: const ColorScheme.light(
        primary: accentBlue,
        secondary: neonBlue,
        tertiary: goldAccent,
        surface: Colors.white,
        background: Color(0xFFF8FAFC),
        error: crimsonRed,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          color: primaryBlue,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withOpacity(0.9),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: accentBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: accentBlue.withOpacity(0.3), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
          letterSpacing: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF334155),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  // Custom Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(lightBlue),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      
      colorScheme: const ColorScheme.dark(
        primary: lightBlue,
        secondary: neonBlue,
        tertiary: goldAccent,
        surface: Color(0xFF1E293B),
        background: Color(0xFF0F172A),
        error: crimsonRed,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: const Color(0xFF1E293B).withOpacity(0.9),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: lightBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B).withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: lightBlue.withOpacity(0.3), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: lightBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFFCBD5E1),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // Helper method to create MaterialColor
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

// Custom Widget Extensions for Glassmorphism
extension GlassmorphismWidget on Widget {
  Widget glassmorphism({
    double blur = 10.0,
    double opacity = 0.2,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(opacity),
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: this,
      ),
    );
  }
  
  Widget withGlow({Color? glowColor, double blurRadius = 20.0}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppTheme.accentBlue).withOpacity(0.4),
            blurRadius: blurRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: this,
    );
  }
}