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
import '../../features/animals/presentation/screens/add_cattle_screen.dart';
import '../../features/ai_tools/presentation/screens/voice_chat_screen.dart';
import '../../features/utilities/presentation/screens/hospital_finder_screen.dart';
import '../../features/utilities/presentation/screens/tele_vet_screen.dart';
import '../../features/utilities/presentation/screens/medicine_info_screen.dart';
import '../../features/utilities/presentation/screens/weather_screen.dart';
import '../../features/utilities/presentation/screens/vaccine_reminder_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../shared/widgets/scaffold_with_bottom_nav.dart';
import '../../features/vet/presentation/screens/vet_dashboard_screen.dart';
import '../../features/vet/presentation/screens/find_vet_screen.dart';
import '../../features/vet/presentation/screens/book_appointment_screen.dart';
import '../../features/vet/presentation/screens/vet_profile_screen.dart';
import '../../features/vet/presentation/screens/vet_appointments_screen.dart';
import '../../features/vet/presentation/screens/vet_slots_screen.dart';
import '../../features/video_call/presentation/screens/video_call_screen.dart';
import '../../features/video_call/presentation/screens/incoming_call_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/vet/presentation/screens/vet_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

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
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithBottomNav(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/animals',
              builder: (context, state) => const AnimalListScreen(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, state) => AnimalDetailScreen(animalData: state.extra as Map<String, dynamic>?),
                ),
                GoRoute(
                  path: 'collar',
                  builder: (context, state) => SmartCollarScreen(deviceCode: (state.extra as String?) ?? 'DEV-124'),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/accounting',
              builder: (context, state) => const AccountingScreen(),
            ),
          ],
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
      builder: (context, state) => const FindVetScreen(),
    ),
    GoRoute(
      path: '/medicine',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MedicineInfoScreen(),
    ),
    GoRoute(
      path: '/weather',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const WeatherScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.08);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeIn);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VaccineReminderScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationScreen(),
    ),

    // ── Vet routes ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/vet-dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VetDashboardScreen(),
    ),
    GoRoute(
      path: '/vet-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VetProfileScreen(),
    ),
    GoRoute(
      path: '/vet-appointments',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VetAppointmentsScreen(),
    ),
    GoRoute(
      path: '/vet-slots',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VetSlotsScreen(),
    ),
    GoRoute(
      path: '/find-vet',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FindVetScreen(),
    ),
    GoRoute(
      path: '/book-appointment/:vetId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final vetId = state.pathParameters['vetId']!;
        final vetData = state.extra as Map<String, dynamic>?;
        return BookAppointmentScreen(vetId: vetId, vetData: vetData);
      },
    ),
    GoRoute(
      path: '/video-call/:roomId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return VideoCallScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/incoming-call',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return IncomingCallScreen(
          roomId: args['roomId'] as String? ?? '',
          callerName: args['callerName'] as String? ?? 'ডাক্তার',
          consultationId: args['consultationId'] as String? ?? '',
          callerSocketId: args['callerSocketId'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/vet-detail/:vetId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final vetId = state.pathParameters['vetId']!;
        final vetData = state.extra as Map<String, dynamic>?;
        return VetDetailScreen(vetId: vetId, vetData: vetData);
      },
    ),
    GoRoute(
      path: '/chat/:otherUserId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final otherUserId = state.pathParameters['otherUserId']!;
        final name = state.uri.queryParameters['name'] ?? 'Chat';
        return ChatScreen(otherUserId: otherUserId, otherUserName: name);
      },
    ),
    GoRoute(
      path: '/chat-list',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/animals/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddCattleScreen(),
    ),
  ],
);
