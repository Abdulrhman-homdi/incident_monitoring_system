import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isExpanded = false;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      setState(() {
        _isExpanded = true;
      });
    });

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,

        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LoginScreen(),

          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },

          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,

      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1000),

                curve: Curves.easeOutBack,

                width: _isExpanded ? 160 : 100,

                child: Image.asset(
                  'assets/images/logo.png',

                  fit: BoxFit.contain,

                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.account_balance,
                    size: 100,
                    color: Color(0xFF2D9373),
                  ),
                ),
              ),
            ),

            const Spacer(),

            const Text(
              "اسم الأمانة باللغة العربية",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Name of Municipality in English",

              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
