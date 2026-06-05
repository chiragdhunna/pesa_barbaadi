import 'package:go_router/go_router.dart';
import 'package:pesa_barbaadi/screens/add_entry/add_entry_screen.dart';
import 'package:pesa_barbaadi/screens/auth/login_screen.dart';
import 'package:pesa_barbaadi/screens/export/export_screen.dart';
import 'package:pesa_barbaadi/screens/history/history_screen.dart';
import 'package:pesa_barbaadi/screens/home/home_screen.dart';
import 'package:pesa_barbaadi/screens/settings/settings_screen.dart';
import 'package:pesa_barbaadi/screens/splash_screen.dart';
import 'package:pesa_barbaadi/screens/trip_setup_screen.dart';

final router = GoRouter(
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
      path: '/trip-setup',
      builder: (context, state) => const TripSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-entry',
      builder: (context, state) => const AddEntryScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) => const ExportScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
