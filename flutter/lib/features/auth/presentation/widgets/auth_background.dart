import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Illustration
        Positioned.fill(
          child: Image.asset(
            'assets/images/login_landscape.png',
            fit: BoxFit.cover,
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF003300).withOpacity(0.85),
                  const Color(0xFF004D40).withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
