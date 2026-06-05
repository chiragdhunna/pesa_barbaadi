import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1. Read SharedPreferences for existing tripId
    final prefs = await SharedPreferences.getInstance();
    final savedTripId = prefs.getString(AppStrings.tripIdKey);

    // 2. If found, update tripIdProvider
    if (savedTripId != null && savedTripId.isNotEmpty) {
      ref.read(tripIdProvider.notifier).state = savedTripId;
    }

    // 3. 300ms delay as specified
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // 4. Check auth state and navigate
    // We use ref.read(authStateProvider) here to get the current value of the stream
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    final currentTripId = ref.read(tripIdProvider);

    if (user != null) {
      if (currentTripId != null) {
        context.go('/home');
      } else {
        context.go('/trip-setup');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_gas_station,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
