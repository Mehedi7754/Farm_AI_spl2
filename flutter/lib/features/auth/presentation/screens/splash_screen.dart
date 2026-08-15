import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../../../../core/services/chat_notification_sync_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Blazing fast 1.2s splash initialization
    await Future.delayed(const Duration(milliseconds: 1200));
    await ApiClient.loadPersistedAuth();

    if (mounted) {
      if (ApiClient.authToken != null && ApiClient.currentUser != null) {
        ref.read(authProvider.notifier).initAuth();
        ChatNotificationSyncService.syncUnreadMessages();
        final role = (ApiClient.currentUser?['role'] ?? 'FARMER').toString().toUpperCase();
        context.go(role == 'VET' ? '/vet-dashboard' : '/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_landscape.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.primaryColor.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
                Text(
                  StringsBn.appName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          const Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
                const SizedBox(height: 8),
                Text(
                  StringsBn.splashSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.1,
                      ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white24,
                    minHeight: 2,
                  ),
                ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.5, 1), end: const Offset(1, 1)),
                const SizedBox(height: 24),
                Text(
                  'POWERED BY ADVANCED AG-TECH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
