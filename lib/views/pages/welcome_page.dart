import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _slideAnimation;

  double _pageOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize AnimationController before using it
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this, // ✅ Ensures proper sync with Flutter's rendering
    );

    // ✅ Define animations after initializing the controller
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.2)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);

    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _slideAnimation = Tween<double>(begin: 30, end: 0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);

    // ✅ Start the animation only after ensuring the controller exists
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward();
      }
    });

    // ✅ Delay the page content fade-in
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _pageOpacity = 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ Properly dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/shose.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(color: AppColors().navy.withValues(alpha: 0.3)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const SizedBox(height: 100),

                  // ✅ Animated "Hire Harmony" Text (Slide-up & Fade-in)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Text(
                            'Hire Harmony',
                            style: GoogleFonts.montserratAlternates(
                              fontSize: 40, // Larger text for emphasis
                              color: AppColors().white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // ✅ Animated Logo (Scale & Fade-in)
                  const SizedBox(height: 70),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Center(
                            child: Image.asset(
                              'lib/assets/images/logo_white_brown_shadow.PNG',
                              width: 200, // Bigger logo for better visibility
                              height: 200,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 90),

                  // ✅ Fade-in Slogan
                  AnimatedOpacity(
                    opacity: _pageOpacity,
                    duration: const Duration(seconds: 1),
                    child: Text(
                      'All services on \nyour fingertips',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: AppColors().white,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ✅ Fade-in Buttons
                  AnimatedOpacity(
                    opacity: _pageOpacity,
                    duration: const Duration(seconds: 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.loginPage);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors().orange,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Log In',
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 18,
                                color: AppColors().white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.signupChoicePage);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 18,
                                color: AppColors().navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
