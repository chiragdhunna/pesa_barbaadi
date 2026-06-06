import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tripId = ref.watch(tripIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          const _SectionHeader(title: 'Account'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        backgroundColor: AppColors.primary,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'No Name',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? 'No Email',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSignOut(context, ref),
                      icon: const Icon(Icons.logout, color: AppColors.danger),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.danger),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trip Section
          const _SectionHeader(title: 'Trip Management'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Trip ID'),
                  subtitle: Text(
                    tripId ?? 'No active trip',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: tripId != null
                        ? () {
                            Clipboard.setData(ClipboardData(text: tripId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trip ID copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                  title: const Text(
                    'Leave Trip',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  subtitle: const Text('You will lose access to this trip'),
                  onTap: tripId != null ? () => _handleLeaveTrip(context, ref) : null,
                ),
              ],
            ),
          ),

          // About Section
          const _SectionHeader(title: 'About'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('Version'),
              trailing: Text(
                '1.0.0',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Clear tripIdProvider
      ref.read(tripIdProvider.notifier).state = null;

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppStrings.tripIdKey);

      // 3. Sign out
      await ref.read(authRepositoryProvider).signOut();

      // 4. Navigate to login
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _handleLeaveTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Trip'),
        content: const Text(
            'Are you sure you want to leave this trip? You will need an invite code to rejoin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(fuelRepositoryProvider);
        if (repo != null) {
          await repo.leaveTrip();
        }

        // Clear local state regardless of repo availability (as a fallback)
        ref.read(tripIdProvider.notifier).state = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppStrings.tripIdKey);

        if (context.mounted) {
          context.go('/trip-setup');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error leaving trip: $e')),
          );
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
