import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/tickets/ticket_list_screen.dart';
import '../features/tickets/ticket_detail_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/leaves/leaves_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/shell/staff_shell_screen.dart';
import '../providers/auth_provider.dart';

GoRouter createRouter(AuthProvider authProvider) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKeyTickets = GlobalKey<NavigatorState>();
  final shellNavigatorKeyAttendance = GlobalKey<NavigatorState>();
  final shellNavigatorKeyLeaves = GlobalKey<NavigatorState>();
  final shellNavigatorKeyProfile = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/tickets',
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (authProvider.isLoading) return null;

      final isAuthenticated = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/tickets';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/ticket/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '0';
          final id = int.tryParse(idStr) ?? 0;
          return TicketDetailScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ScanScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StaffShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeyTickets,
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (context, state) => const TicketListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeyAttendance,
            routes: [
              GoRoute(
                path: '/attendance',
                builder: (context, state) => const AttendanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeyLeaves,
            routes: [
              GoRoute(
                path: '/leaves',
                builder: (context, state) => const LeavesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorKeyProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
