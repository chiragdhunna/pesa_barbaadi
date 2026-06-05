import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(tripIdProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Trip Information'),
          _SettingsTile(
            title: 'Trip ID',
            subtitle: tripId ?? 'Not in a trip',
            icon: Icons.vpn_key_outlined,
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
              onPressed: tripId != null
                  ? () {
                      Clipboard.setData(ClipboardData(text: tripId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Trip ID copied to clipboard')),
                      );
                    }
                  : null,
            ),
          ),
          _SettingsTile(
            title: 'Share Trip Code',
            subtitle: 'Invite your friend to this trip',
            icon: Icons.share_outlined,
            onTap: tripId != null
                ? () {
                    Share.share(
                        'Join my Pesa Barbaadi trip! Use code: $tripId');
                  }
                : null,
          ),
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            title: 'Logged in as',
            subtitle: user?.email ?? 'Unknown',
            icon: Icons.person_outline,
          ),
          _SettingsTile(
            title: 'Sign out',
            subtitle: 'Log out from your account',
            icon: Icons.logout,
            iconColor: AppColors.danger,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Sign out',
                      style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text('Are you sure you want to sign out?',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign out',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                // 1. Clear SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(AppStrings.tripIdKey);

                // 2. Clear Provider
                ref.read(tripIdProvider.notifier).state = null;

                // 3. Sign out from Auth
                await ref.read(authRepositoryProvider).signOut();

                // 4. Navigate to Login
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
          const _SectionHeader(title: 'App Info'),
          const _SettingsTile(
            title: 'Version',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
