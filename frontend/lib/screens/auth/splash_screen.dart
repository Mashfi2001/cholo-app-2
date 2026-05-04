import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import 'onboarding_screen.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _nameSlide;
  late Animation<double> _nameOpacity;

  @override
  void initState() {
    super.initState();

    // Set status bar to light (for dark background)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Logo fades in (300ms)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.43, curve: Curves.easeOut),
      ),
    );

    // Name slides up (400ms delay, starts at ~57% of total animation)
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.57, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.57, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();

    // Navigate after 2 seconds
    Timer(const Duration(seconds: 2), () {
      // TODO: Check if user is returning or first time install
      // For now, navigate to Onboarding (first install flow)
      // In production, check SharedPreferences for 'hasSeenOnboarding'
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with fade in animation
              AnimatedBuilder(
                animation: _logoOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_taxi,
                        size: 48,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // App name with slide up animation
              AnimatedBuilder(
                animation: _nameSlide,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _nameSlide.value,
                    child: Opacity(
                      opacity: _nameOpacity.value,
                      child: Text(
                        'Cholo',
                        style: AppTextStyles.headingXL,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Tagline
              AnimatedBuilder(
                animation: _nameOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _nameOpacity.value,
                    child: Text(
                      'Your ride, your way.',
                      style: AppTextStyles.bodyM,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
