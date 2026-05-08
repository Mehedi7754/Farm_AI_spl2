import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/animals/presentation/screens/animal_list_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/utilities/presentation/screens/accounting_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/ai_tools/presentation/screens/symptom_analysis_screen.dart';
import '../../features/ai_tools/presentation/screens/ai_result_screen.dart';
import '../../features/animals/presentation/screens/animal_detail_screen.dart';
import '../../features/animals/presentation/screens/smart_collar_screen.dart';
import '../../features/ai_tools/presentation/screens/voice_chat_screen.dart';
import '../../features/utilities/presentation/screens/hospital_finder_screen.dart';
import '../../features/utilities/presentation/screens/tele_vet_screen.dart';
import '../../features/utilities/presentation/screens/medicine_info_screen.dart';
import '../../features/utilities/presentation/screens/weather_screen.dart';
import '../../features/utilities/presentation/screens/vaccine_reminder_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../shared/widgets/scaffold_with_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithBottomNav(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/animals',
          builder: (context, state) => const AnimalListScreen(),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, state) => const AnimalDetailScreen(),
            ),
            GoRoute(
              path: 'collar',
              builder: (context, state) => const SmartCollarScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/accounting',
          builder: (context, state) => const AccountingScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/ai/symptom',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SymptomAnalysisScreen(),
    ),
    GoRoute(
      path: '/ai/result',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AIResultScreen(),
    ),
    GoRoute(
      path: '/ai/voice',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VoiceChatScreen(),
    ),
    GoRoute(
      path: '/hospital',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HospitalFinderScreen(),
    ),
    GoRoute(
      path: '/televet',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeleVetScreen(),
    ),
    GoRoute(
      path: '/medicine',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MedicineInfoScreen(),
    ),
    GoRoute(
      path: '/weather',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WeatherScreen(),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VaccineReminderScreen(),
    ),
  ],
);
