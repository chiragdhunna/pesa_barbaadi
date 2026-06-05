import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/repositories/fuel_repository.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripSetupScreen extends ConsumerStatefulWidget {
  const TripSetupScreen({super.key});

  @override
  ConsumerState<TripSetupScreen> createState() => _TripSetupScreenState();
}

class _TripSetupScreenState extends ConsumerState<TripSetupScreen> {
  final TextEditingController _joinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingTrip();
  }

  Future<void> _checkExistingTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTripId = prefs.getString(AppStrings.tripIdKey);
    if (savedTripId != null && savedTripId.isNotEmpty && mounted) {
      ref.read(tripIdProvider.notifier).state = savedTripId;
      context.go('/home');
    }
  }

  Future<void> _saveTripId(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStrings.tripIdKey, tripId);
    ref.read(tripIdProvider.notifier).state = tripId;
  }

  Future<void> _handleCreateTrip() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final tripId = await FuelRepository.createTrip(
        user.uid,
        user.displayName ?? 'User',
      );
      await _saveTripId(tripId);
      if (mounted) {
        _showShareSheet(tripId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating trip: $e')),
        );
      }
    }
  }

  Future<void> _handleJoinTrip() async {
    final tripId = _joinController.text.trim();
    if (tripId.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final repo = FuelRepository(tripId: tripId, currentUserUid: user.uid);
      await repo.joinTrip(tripId, user.uid, user.displayName ?? 'User');
      await _saveTripId(tripId);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining trip: $e')),
        );
      }
    }
  }

  void _showShareSheet(String tripId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with your friend:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SelectableText(
              tripId,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tripId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied!')),
                  );
                },
                child: const Text('Copy code'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Share.share('Join my Pesa Barbaadi trip! Use code: $tripId');
                },
                child: const Text('Share via WhatsApp / other'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Continue to app'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set up your trip'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome! To start tracking, you need to either create a new shared trip or join one your friend already created.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      title: 'Create new trip',
                      icon: Icons.add_circle_outline,
                      onTap: _handleCreateTrip,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOptionCard(
                      title: 'Join existing trip',
                      icon: Icons.group_add_outlined,
                      onTap: () => _showJoinDialog(),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Join existing trip',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: _joinController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter Trip ID',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textMuted)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleJoinTrip();
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
