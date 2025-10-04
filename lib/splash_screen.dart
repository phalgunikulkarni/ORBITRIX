import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _leftCarController;
  late AnimationController _rightCarController;
  late AnimationController _collisionController;
  late AnimationController _alertController;
  late AnimationController _fadeController;
  
  late Animation<double> _leftCarAnimation;
  late Animation<double> _rightCarAnimation;
  late Animation<double> _collisionScale;
  late Animation<double> _alertOpacity;
  late Animation<double> _alertScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Left car animation controller
    _leftCarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Right car animation controller
    _rightCarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Collision animation controller
    _collisionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Alert animation controller
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Car animations - moving towards each other
    _leftCarAnimation = Tween<double>(begin: -0.5, end: 0.35).animate(
      CurvedAnimation(parent: _leftCarController, curve: Curves.easeInOut),
    );

    _rightCarAnimation = Tween<double>(begin: 1.5, end: 0.65).animate(
      CurvedAnimation(parent: _rightCarController, curve: Curves.easeInOut),
    );

    // Collision scale animation
    _collisionScale = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _collisionController, curve: Curves.elasticOut),
    );

    // Alert animations
    _alertOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.easeInOut),
    );

    _alertScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.elasticOut),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animation sequence
    _startAnimationSequence();

    // Navigate to login page after animations
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  void _startAnimationSequence() async {
    // Start fade in
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start cars moving towards each other
    _leftCarController.forward();
    _rightCarController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Collision effect
    _collisionController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Alert animations
    _alertController.forward();
  }

  @override
  void dispose() {
    _leftCarController.dispose();
    _rightCarController.dispose();
    _collisionController.dispose();
    _alertController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000), // Black
              Color(0xFF1E3A8A), // Dark Blue
              Color(0xFF3B82F6), // Blue
            ],
          ),
        ),
        child: Column(
          children: [
            // Top spacing
            const Spacer(flex: 2),
            
            // Main content with fade animation - V2V text centered
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // App title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF), // White
                            Color(0xFF3B82F6), // Blue
                            Color(0xFFFFFFFF), // White
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "V2V",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          "Smart Collision Alert System",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Spacing between text and animation
            const SizedBox(height: 60),
            
            // Car collision animation positioned below the text
            SizedBox(
              height: 200,
              width: double.infinity,
                child: Stack(
                  children: [
                    // Left car
                    AnimatedBuilder(
                      animation: _leftCarAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * _leftCarAnimation.value,
                          top: 80,
                          child: Transform.rotate(
                            angle: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Right car
                    AnimatedBuilder(
                      animation: _rightCarAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * _rightCarAnimation.value,
                          top: 80,
                          child: Transform.rotate(
                            angle: math.pi,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Collision effect
                    AnimatedBuilder(
                      animation: _collisionScale,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * 0.5 - 30,
                          top: 70,
                          child: Transform.scale(
                            scale: _collisionScale.value,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(0.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.6),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Alert waves
                    AnimatedBuilder(
                      animation: _alertController,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * 0.5 - 60,
                          top: 40,
                          child: Opacity(
                            opacity: _alertOpacity.value,
                            child: Transform.scale(
                              scale: _alertScale.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.6),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Secondary alert wave
                    AnimatedBuilder(
                      animation: _alertController,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * 0.5 - 80,
                          top: 20,
                          child: Opacity(
                            opacity: _alertOpacity.value * 0.6,
                            child: Transform.scale(
                              scale: _alertScale.value * 1.3,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ),
            
            // Bottom spacing
            const Spacer(flex: 1),
            
            // Loading indicator at bottom
            Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  "Initializing Collision Detection...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            
            // Bottom padding
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}